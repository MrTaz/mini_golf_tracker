import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/dashboard_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/gravatar_image_view.dart';
import 'package:mini_golf_tracker/player_avatar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SimpleMockGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.denied;
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  
  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([
      [71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 128, 0, 0, 0, 0, 0, 255, 255, 255, 33, 249, 4, 1, 0, 0, 0, 0, 44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 76, 1, 0, 59]
    ]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().setAuthInstanceForTesting(mockAuth);
    SharedPreferences.setMockInitialValues({});
    GeolocatorPlatform.instance = SimpleMockGeolocator();
    UserProvider().resetForTesting();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  Widget createDashboardScreen() {
    return const MaterialApp(
      home: DashboardScreen(),
    );
  }

  testWidgets('renders BottomNavigationBar for logged-in users', (tester) async {
    final player = Player(
      id: 'p123',
      playerName: 'Test Player',
      nickname: 'Tester',
      ownerId: 'p123',
      totalScore: 0,
      email: 'test@example.com',
    );
    await UserProvider().login(player);

    await tester.pumpWidget(createDashboardScreen());
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('does not render BottomNavigationBar for guest users', (tester) async {
    // Keep user logged out (guest)
    await tester.pumpWidget(createDashboardScreen());
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('supports navigation and tapping Friends card', (tester) async {
    final player = Player(
      id: 'p123',
      playerName: 'Test Player',
      nickname: 'Tester',
      ownerId: 'p123',
      totalScore: 0,
      email: 'test@example.com',
      avatarImageLocation: 'http://example.com/avatar.png',
    );
    await UserProvider().login(player);

    await tester.pumpWidget(createDashboardScreen());
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 1. Check user avatar renders through the shared PlayerAvatarWidget email branch.
    expect(find.byType(PlayerAvatarWidget), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    final gravatar = tester.widget<GravatarImageView>(
      find.byType(GravatarImageView),
    );
    expect(gravatar.email, 'test@example.com');

    // 2. Cover notifyListeners / _onUserChanged (lines 121-123)
    UserProvider().loggedInUser = player;
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 3. Find and tap Friends PlayersCard to cover lines 197-200 and lines 42-44
    await tester.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PlayersCard'));
    await tester.pumpAndSettle();

    // Since the callback updateBottomNavChangeNotifier was called, it navigated to index 1 (Friends/PlayersScreen)
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PlayersScreen'), findsOneWidget);

    // 4. Tap another bottom navigation bar item to cover other branches in _updateBody / _pages (lines 46-54)
    // Tapping 'Past Games'
    await tester.tap(find.text('Past Games'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PastGamesScreen'), findsOneWidget);

    // Tapping 'Courses'
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'CoursesScreen'), findsOneWidget);

    // Tapping 'Home'
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DashBoardLayout'), findsOneWidget);
  });
}

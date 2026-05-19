import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
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

class FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return ByteData.sublistView(Uint8List.fromList([13, 0]));
    }
    if (key == 'AssetManifest.json') {
      return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
    }
    if (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.gif')) {
      return ByteData.sublistView(Uint8List.fromList([
        71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 128, 0, 0, 0, 0, 0, 255, 255, 255, 33, 249, 4, 1, 0, 0, 0, 0, 44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 76, 1, 0, 59
      ]));
    }
    throw FlutterError('Asset not found: $key');
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
    GeolocatorPlatform.instance = SimpleMockGeolocator();
    UserProvider().resetForTesting();
    MainScaffold.skipPrecacheForTesting = true;
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  Widget createMyApp() {
    return DefaultAssetBundle(
      bundle: FakeAssetBundle(),
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }

  testWidgets('renders HomePage guest shell drawer and navigates to LoginScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(createMyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));


    // Verify HomePage builds and has an AppBar with title
    expect(find.text('Mini Golf Tracker'), findsOneWidget);

    // Open standard Scaffold drawer
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify guest drawer items
    expect(find.text('Guest Profile'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Past Games'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);

    // Tap Friends and verify we navigate to LoginScreen
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    // Let any pending login screen animations or timers complete
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('renders HomePage drawer for logged in user', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final player = Player(
      id: 'p123',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p123',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);

    await tester.pumpWidget(createMyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Jane Doe'), findsNWidgets(2));
    expect(find.text('Janie'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
  });

  testWidgets('auto-resumes active local game for guests upon startup', (tester) async {
    final course = Course(
      id: 'c1',
      name: 'Startup Course',
      numberOfHoles: 1,
      parStrokes: {1: 3},
    );
    final playerGameInfo = PlayerGameInfo(
      playerId: 'p1',
      gameId: 'g1',
      scores: [2],
    );
    final game = Game(
      id: 'g1',
      name: 'Resumed Game',
      course: course,
      players: [playerGameInfo],
      scheduledTime: DateTime.now(),
      status: 'started',
    );
    final gameJson = jsonEncode(game.toJson());

    // Mock active game in SharedPreferences
    SharedPreferences.setMockInitialValues({
      'g1': gameJson,
    });

    await tester.pumpWidget(createMyApp());
    
    // Pump first frame
    await tester.pump();
    
    // Now pump with a duration to let timers/microtasks and future builder complete
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Verify it automatically switched the body to GameInprogressScreen
    expect(find.byType(GameInprogressScreen), findsOneWidget);
    expect(find.textContaining('Startup Course'), findsOneWidget);
  });
}

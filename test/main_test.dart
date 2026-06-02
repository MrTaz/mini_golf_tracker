import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/app_drawer_widget.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/main.dart' as app;
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:mini_golf_tracker/claim_account_screen.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/dashboard_screen.dart';

class SimpleMockGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
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
      [
        71,
        73,
        70,
        56,
        57,
        97,
        1,
        0,
        1,
        0,
        128,
        0,
        0,
        0,
        0,
        0,
        255,
        255,
        255,
        33,
        249,
        4,
        1,
        0,
        0,
        0,
        0,
        44,
        0,
        0,
        0,
        0,
        1,
        0,
        1,
        0,
        0,
        2,
        2,
        76,
        1,
        0,
        59
      ]
    ]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({})!;
    }
    if (key == 'AssetManifest.json') {
      final manifest = {
        "assets/images/rank1.png": ["assets/images/rank1.png"],
        "assets/images/rank2.png": ["assets/images/rank2.png"],
        "assets/images/rank3.png": ["assets/images/rank3.png"],
        "assets/images/mini_golf_placeholder.png": [
          "assets/images/mini_golf_placeholder.png"
        ],
        "assets/images/loggedin_background_2.png": [
          "assets/images/loggedin_background_2.png"
        ],
      };
      return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(jsonEncode(manifest))));
    }
    if (key.endsWith('.png') ||
        key.endsWith('.jpg') ||
        key.endsWith('.jpeg') ||
        key.endsWith('.gif')) {
      return ByteData.sublistView(Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]));
    }
    throw FlutterError('Asset not found: $key');
  }
}

Future<void> openHomePageDrawer(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final scaffoldState = tester.firstState<ScaffoldState>(
    find.byWidgetPredicate(
      (widget) => widget is Scaffold && widget.drawer is AppDrawer,
    ),
  );
  scaffoldState.openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    UserProvider().resetForTesting();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().setAuthInstanceForTesting(mockAuth);
    GeolocatorPlatform.instance = SimpleMockGeolocator();
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

  testWidgets('auto-resumes active local game for guests upon startup',
      (tester) async {
    final course = Course(
      id: 'c1',
      name: 'Startup Course',
      numberOfHoles: 1,
      parStrokes: {1: 3},
    );
    final playerGameInfo = PlayerGameInfo(
      playerId: 'p1',
      gameId: 'g1',
      scores: [1],
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

  testWidgets('executes main method successfully', (tester) async {
    setupFirebaseCoreMocks();
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await app.main();
      await Future.delayed(const Duration(milliseconds: 100));
    });
  });

  testWidgets('MyApp routes and builds MaterialApp correctly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Putt Scorer'), findsOneWidget);

    final context = tester.element(find.byType(HomePage));
    Navigator.pushNamed(context, '/players');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PlayersScreen), findsOneWidget);
  });

  testWidgets('precache is run when skipPrecacheForTesting is false',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    MainScaffold.skipPrecacheForTesting = false;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: FakeAssetBundle(),
            child: const HomePage(),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.text('Putt Scorer'), findsOneWidget);

    MainScaffold.skipPrecacheForTesting = true;
  });

  testWidgets('onUserChanged triggers setState when UserProvider updates',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HomeScreen), findsOneWidget);

    final player = Player(
      id: 'p123',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p123',
      totalScore: 0,
      email: 'jane@example.com',
      avatarImageLocation: 'http://example.com/avatar.png',
    );
    await UserProvider().login(player);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('renders ClaimAccountScreen when pendingClaimPlayer is set',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final player = Player(
      id: 'p123',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p123',
      totalScore: 0,
      email: 'jane@example.com',
    );
    UserProvider().beginPendingClaim(player);

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ClaimAccountScreen), findsOneWidget);
  });

  testWidgets('MainScaffold refresh and logout hooks update shell state',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final state = tester.state<MainScaffold>(find.byType(HomePage));
    state.changeBodyCallback(const Text('Changed Body'));
    await tester.pump();
    expect(find.text('Changed Body'), findsOneWidget);

    state.refreshDrawerState();
    await tester.pump();
    state.didPopNext();
    await tester.pump();

    final player = Player(
      id: 'p123',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p123',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);
    await tester.pump();
    expect(UserProvider().loggedInUser, isNotNull);

    state.logout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(UserProvider().loggedInUser, isNull);
  });

  testWidgets('MainScaffold drawer onTabSelected callback works',
      (tester) async {
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

    await openHomePageDrawer(tester);

    final friendsTile = find.byKey(const Key('drawer-friends'));
    await tester.tap(friendsTile);
    await tester.pumpAndSettle();

    final bottomNavBar =
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bottomNavBar.currentIndex, equals(1));
  });
}

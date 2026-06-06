// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/features/players/presentation/screens/players_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/past_games_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

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

void main() {
  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();
    final fakeFirestore = FakeFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(mockAuth);
    SharedPreferences.setMockInitialValues({});
    MainScaffold.skipPrecacheForTesting = true;
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  patrolTest(
    'E2E Patrol: open side menu and tap Friends or Past Games - navigates to screen and preserves BottomNavigationBar',
    ($) async {
      // 1. Seed a logged-in user
      final player = Player(
        id: 'p1',
        playerName: 'Jane Doe',
        nickname: 'Janie',
        ownerId: 'p1',
        totalScore: 0,
        email: 'jane@example.com',
      );
      await UserProvider().login(player);

      // 2. Boot the full app with mocked AssetBundle
      await $.pumpWidgetAndSettle(
        DefaultAssetBundle(
          bundle: FakeAssetBundle(),
          child: const MyApp(),
        ),
      );

      // Verify we are on DashboardScreen and BottomNavigationBar is visible
      expect($(DashboardScreen), findsOneWidget);
      expect($(BottomNavigationBar), findsOneWidget);

      // Helper to open drawer and wait for the FutureBuilder to load the list tiles
      Future<void> openDrawerAndWait() async {
        final scaffoldFinder = find.byType(Scaffold);
        final scaffoldState =
            $.tester.firstState<ScaffoldState>(scaffoldFinder);
        scaffoldState.openDrawer();
        await $.pump();
        await $.pump(const Duration(milliseconds: 500));

        // Wait for the drawer's FutureBuilder to complete and list tiles to appear
        int retries = 0;
        while (find.byKey(const Key('drawer-friends')).evaluate().isEmpty &&
            retries < 20) {
          await $.pump(const Duration(milliseconds: 100));
          retries++;
        }
      }

      // 3. Open drawer
      await openDrawerAndWait();

      // 4. Tap Friends
      final friendsTile = find.byKey(const Key('drawer-friends'));
      expect(friendsTile, findsOneWidget);
      await $(friendsTile).tap();
      await $.pumpAndSettle();

      // Verify we navigated to PlayersScreen and BottomNavigationBar remains visible
      expect($(PlayersScreen), findsOneWidget);
      expect($(BottomNavigationBar), findsOneWidget);

      // 5. Open drawer again
      await openDrawerAndWait();

      // 6. Tap Past Games
      final pastGamesTile = find.byKey(const Key('drawer-past-games'));
      expect(pastGamesTile, findsOneWidget);
      await $(pastGamesTile).tap();
      await $.pumpAndSettle();

      // Verify we navigated to PastGamesScreen and BottomNavigationBar remains visible
      expect($(PastGamesScreen), findsOneWidget);
      expect($(BottomNavigationBar), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/past_games_list_view.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirestoreWithError implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw FirebaseException(plugin: 'firestore', message: 'Simulated failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A helper that sets a standard large view size so no overflow occurs.
void _setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Minimal wrap used in all tests.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Column(children: [Expanded(child: child)]),
    ),
  );
}

void main() {
  setUp(() {
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
  });

  testWidgets('PastGamesListView throws when not logged in', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PastGamesListView())));
    expect(tester.takeException(), isNotNull);
  });

  testWidgets(
      'PastGamesListView renders with games when logged in, supports tap, separator, and ties',
      (tester) async {
    _setLargeScreen(tester);

    final creator = Player(
      id: 'creator1',
      playerName: 'Jane',
      nickname: 'Jane',
      ownerId: 'creator1',
      totalScore: 0,
    );
    final friend = Player(
      id: 'friend1',
      playerName: 'Bob',
      nickname: 'Bob',
      ownerId: 'creator1',
      totalScore: 0,
    );
    Player.players.add(friend);
    await UserProvider().login(creator);
    // Re-add friend after login to ensure they are in the players list post-login cleanup
    if (!Player.players.any((p) => p.id == friend.id)) {
      Player.players.add(friend);
    }

    final game1 = Game(
      id: 'g1',
      name: 'Test Game 1',
      course: Course(id: 'c1', name: 'Pinecrest', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'creator1', gameId: 'g1', scores: [2]),
        PlayerGameInfo(playerId: 'friend1', gameId: 'g1', scores: [2]),
      ],
      scheduledTime: DateTime(2026, 1, 1),
      startTime: DateTime(2026, 1, 1),
      completedTime: DateTime(2026, 1, 1),
      status: 'completed',
    );

    final game2 = Game(
      id: 'g2',
      name: 'Test Game 2',
      course: Course(id: 'c2', name: 'Oakridge', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'creator1', gameId: 'g2', scores: [3]),
      ],
      scheduledTime: DateTime(2026, 1, 2),
      startTime: DateTime(2026, 1, 2),
      completedTime: DateTime(2026, 1, 2),
      status: 'completed',
    );

    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    await Game.saveGameToDatabase(game1, creator);
    await Game.saveGameToDatabase(game2, creator);

    await tester.pumpWidget(_wrap(PastGamesListView(
      startTimeFormatter: (dt) async => 'Jan 1, 2026',
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Pinecrest'), findsOneWidget);
    expect(find.text('Oakridge'), findsOneWidget);
    expect(find.text('Winners: Jane, Bob'), findsOneWidget);
    expect(find.text('Winner: Jane'), findsOneWidget);

    // Verify separator is present between two items
    expect(find.byType(Divider), findsAtLeast(1));

    // Tap on Pinecrest
    await tester.tap(find.text('Pinecrest'));
    await tester.pumpAndSettle();
    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
  });

  testWidgets("PastGamesListView renders Let's play! when no games exist",
      (tester) async {
    _setLargeScreen(tester);

    final creator = Player(
      id: 'creator1',
      playerName: 'Jane',
      nickname: 'Jane',
      ownerId: 'creator1',
      totalScore: 0,
    );
    await UserProvider().login(creator);

    await tester.pumpWidget(_wrap(PastGamesListView()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("Let's play!"), findsOneWidget);
  });

  testWidgets(
      'PastGamesListView catches load errors and sets _isLoading false',
      (tester) async {
    _setLargeScreen(tester);

    final creator = Player(
      id: 'creator1',
      playerName: 'Jane',
      nickname: 'Jane',
      ownerId: 'creator1',
      totalScore: 0,
    );
    await UserProvider().login(creator);

    DatabaseConnection.setFirestoreInstanceForTesting(MockFirestoreWithError());

    await tester.pumpWidget(_wrap(PastGamesListView()));
    await tester.pump();
    await tester.pumpAndSettle();

    // After error, it falls through to the empty state
    expect(find.text("Let's play!"), findsOneWidget);
  });

  testWidgets(
      'PastGamesListView renders FutureBuilder error state when formatter fails',
      (tester) async {
    _setLargeScreen(tester);

    final creator = Player(
      id: 'creator1',
      playerName: 'Jane',
      nickname: 'Jane',
      ownerId: 'creator1',
      totalScore: 0,
    );
    await UserProvider().login(creator);

    final game = Game(
      id: 'g1',
      name: 'Error Game',
      course: Course(id: 'c1', name: 'Error Hills', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'creator1', gameId: 'g1', scores: [2]),
      ],
      scheduledTime: DateTime(2026, 1, 1),
      startTime: DateTime(2026, 1, 1),
      completedTime: DateTime(2026, 1, 1),
      status: 'completed',
    );

    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    await Game.saveGameToDatabase(game, creator);

    // Inject a formatter that always throws so the FutureBuilder error branch is hit
    await tester.pumpWidget(_wrap(PastGamesListView(
      startTimeFormatter: (_) async => throw Exception('Formatting failed'),
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
  });
}

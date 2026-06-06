import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/courses/data/models/course.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_start_screen.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/scheduled_games_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A FirebaseFirestore stub that throws on any collection() call,
/// used to simulate Firestore being offline.
class MockFirestoreWithError implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw FirebaseException(plugin: 'firestore', message: 'Simulated failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [];
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    Player.players = [];
  });

  testWidgets('shows loading then empty state when no games exist',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('No scheduled games'), findsOneWidget);
  });

  testWidgets('renders list of scheduled games', (tester) async {
    final game = Game(
      id: 'g1',
      name: 'Upcoming Test Game',
      course: Course(
        id: 'c1',
        name: 'Test Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'g1',
          scores: [0],
        )
      ],
      scheduledTime: DateTime(2026, 1, 1, 10, 0),
      status: 'unstarted_game',
    );

    SharedPreferences.setMockInitialValues({
      'g1': jsonEncode(game.toJson()),
    });

    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Test Game'), findsOneWidget);
    expect(find.textContaining('Test Course'), findsOneWidget);
  });

  testWidgets(
      'tapping a game navigates to GameStartScreen and reloads games on return',
      (tester) async {
    final game = Game(
      id: 'g1',
      name: 'Upcoming Test Game',
      course: Course(
        id: 'c1',
        name: 'Test Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'g1',
          scores: [1], // Use 1 to prevent DropdownMenuItem value error
        )
      ],
      scheduledTime: DateTime(2026, 1, 1, 10, 0),
      status: 'unstarted_game',
    );

    SharedPreferences.setMockInitialValues({
      'g1': jsonEncode(game.toJson()),
    });

    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upcoming Test Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameStartScreen), findsOneWidget);

    // Now tap back to trigger the pop and reload
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduledGamesScreen), findsOneWidget);
  });

  testWidgets('shows offline banner when _isOffline is true', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    final state = tester
        .state<ScheduledGamesScreenState>(find.byType(ScheduledGamesScreen));

    // Manually set offline state
    state.setOfflineForTesting(true);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.textContaining('Offline mode: showing cached scheduled games'),
        findsOneWidget);
  });

  testWidgets(
      'shows offline empty-state message when offline and no scheduled games',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    final state = tester
        .state<ScheduledGamesScreenState>(find.byType(ScheduledGamesScreen));

    state.setOfflineForTesting(true);
    state.clearScheduledGamesForTesting();
    await tester.pumpAndSettle();

    expect(
        find.textContaining(
            "We couldn't sync your scheduled games. Please check your internet connection"),
        findsOneWidget);
  });

  testWidgets(
      'logged-in user: saves cloud games locally when Firestore succeeds (covers line 51)',
      (tester) async {
    final user = Player(
      id: 'u1',
      playerName: 'Alice',
      nickname: 'Alice',
      ownerId: 'u1',
      totalScore: 0,
    );
    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);

    // Create an unstarted game in Firestore for the user
    final scheduledGame = Game(
      id: 'sched_g1',
      name: 'Cloud Scheduled Game',
      course: Course(
          id: 'c1', name: 'Cloud Hills', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'u1', gameId: 'sched_g1', scores: [0]),
      ],
      scheduledTime: DateTime(2030, 6, 1, 10, 0),
      status: 'unstarted_game',
    );
    await Game.saveGameToDatabase(scheduledGame, user);

    await UserProvider().login(user);

    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    // The cloud game should be saved locally and displayed
    expect(find.text('Cloud Scheduled Game'), findsOneWidget);
  });

  testWidgets(
      'logged-in user: shows offline state when Firestore fetch fails (covers lines 54-55)',
      (tester) async {
    final user = Player(
      id: 'u1',
      playerName: 'Alice',
      nickname: 'Alice',
      ownerId: 'u1',
      totalScore: 0,
    );
    await UserProvider().login(user);

    // After login, make Firestore throw to simulate going offline
    DatabaseConnection.setFirestoreInstanceForTesting(MockFirestoreWithError());

    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    // Without any local games, the offline empty state should show
    expect(
        find.textContaining(
            "We couldn't sync your scheduled games. Please check your internet connection"),
        findsOneWidget);
  });
}

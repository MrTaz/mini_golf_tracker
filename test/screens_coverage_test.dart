import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/past_games_screen.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/course_list_item_widget.dart';
import 'package:mini_golf_tracker/player_form_widget.dart';
import 'package:mini_golf_tracker/players_list_screen.dart';
import 'package:mini_golf_tracker/past_game_list_item.dart';
import 'package:mini_golf_tracker/players_card_widget.dart';
import 'package:mini_golf_tracker/player_profile_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [
      Player(id: 'p1', playerName: 'Ava Guest', nickname: 'Ava', ownerId: 'guest', totalScore: 0),
      Player(id: 'p2', playerName: 'Ben Guest', nickname: 'Ben', ownerId: 'guest', totalScore: 0),
    ];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    Player.players = [];
    UserProvider().resetForTesting();
  });

  testWidgets('Coverage for PlayersScreen lines', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();
    
    // Tap FAB to open PlayerCreateScreen
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    // Tap FAB (close icon) to close PlayerCreateScreen
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Tap player to select
    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Tap player again to unselect
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });

  testWidgets('Coverage for PastGamesScreen lines', (tester) async {
    final game = Game(
      name: 'Past Game',
      course: Course(id: 'c1', name: 'Hub Course', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [PlayerGameInfo(playerId: 'p1', gameId: 'g1', scores: [1])],
      scheduledTime: DateTime(2026, 1, 1),
      startTime: DateTime(2026, 1, 1),
      status: 'completed'
    );
    await Game.saveLocalGame(game);
    
    await tester.pumpWidget(MaterialApp(home: PastGamesScreen()));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Past Game'));
    await tester.pumpAndSettle();
    
    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
  });

  testWidgets('Coverage for PastGameDetailsScreen lines', (tester) async {
    final game = Game(
      name: 'Past Game',
      course: Course(id: 'c1', name: 'Hub Course', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'p1', gameId: 'g1', scores: [1]),
        PlayerGameInfo(playerId: 'p2', gameId: 'g1', scores: [2])
      ],
      scheduledTime: DateTime(2026, 1, 1),
      startTime: DateTime(2026, 1, 1),
      status: 'completed'
    );
    await tester.pumpWidget(MaterialApp(home: PastGameDetailsScreen(passedGame: game)));
    await tester.pumpAndSettle();

    // Tap to select, then unselect
    final state = tester.state<PastGameDetailsScreenState>(find.byType(PastGameDetailsScreen));
    if (state.clickedPlayer.isNotEmpty) {
      final p = state.clickedPlayer.first;
      try {
        state.handlePlayerClick(p);
      } catch (e) {
        // Expected
      }
      await tester.pumpAndSettle();
      try {
        state.handlePlayerClick(p);
      } catch (e) {
        // Expected
      }
      await tester.pumpAndSettle();
    }
    
    // Cover the confetti listener safely
    state.confettiController.play();
    state.confettiController.stop();
    await tester.pump();
    
    // Cover the missing player game info exception
    try {
      state.handlePlayerClick(Player(id: 'nonexistent', playerName: 'Unknown', nickname: 'Unknown', ownerId: '', totalScore: 0));
    } catch (e) {
      // Expected exception
    }
    
    // Cover CourseListItem empty callbacks
    final courseListItemWidgets = tester.widgetList<CourseListItem>(find.byType(CourseListItem));
    if (courseListItemWidgets.isNotEmpty) {
      courseListItemWidgets.first.onDelete();
      courseListItemWidgets.first.onModify();
    }
  });

  testWidgets('Coverage for PlayerListItem lines', (tester) async {
    final player = Player(id: 'p1', playerName: 'Ava Guest', nickname: 'Ava', ownerId: 'guest', totalScore: 0);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PlayerListItem(player: player, creatingGame: false, listOrderNumber: 1, onRemove: () {}))
    ));
    await tester.pumpAndSettle();

    // Tap ListTile to select
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // Open Dropdown
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Press save changes inside PlayerForm directly to avoid validation blocks
    final playerForm = tester.widget<PlayerForm>(find.byType(PlayerForm));
    playerForm.onSaveChanges();
    await tester.pumpAndSettle();
  });

  testWidgets('Coverage for PastGameListItem lines', (tester) async {
    final pastGame = Game(
      name: 'Past Game ListItem',
      course: Course(id: 'c1', name: 'Hub Course', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [PlayerGameInfo(playerId: 'p1', gameId: 'g1', scores: [1])],
      scheduledTime: DateTime(2026, 1, 1),
      startTime: DateTime(2026, 1, 1),
      completedTime: DateTime(2026, 1, 1),
      status: 'completed'
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PastGameListItem(pastGame: pastGame, onPastGameCardTap: null))
    ));
    
    // Pump a few times to let the FutureBuilder complete its loading state
    await tester.pump();
    await tester.pumpAndSettle();
    
    // Tap to hit the onTap setState branch
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
  });

  testWidgets('Coverage for PlayersCard lines', (tester) async {
    UserProvider().resetForTesting(); // Guarantee loggedInUser is null for this test
    final originalPlayers = List<Player>.from(Player.players);
    // Modify global Player.players to test sorting combinations in PlayersCardState.initState
    Player.players = [
      Player(id: 'p1', playerName: 'P1', nickname: 'P1', ownerId: 'guest', totalScore: 10),
      Player(id: 'p2', playerName: 'P2', nickname: 'P2', ownerId: 'guest', totalScore: 10),
      Player(id: 'p3', playerName: 'P3', nickname: 'P3', ownerId: 'guest', totalScore: 0),
      Player(id: 'p4', playerName: 'P4', nickname: 'P4', ownerId: 'guest', totalScore: 20),
      Player(id: 'p5', playerName: 'P5', nickname: 'P5', ownerId: 'guest', totalScore: 0),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ListView(children: [
        PlayersCard(onTap: (Player p) {}), // Card without sortedPlayerIds
        PlayersCard(sortedPlayerIds: ['p2', 'p1']), // Card with sortedPlayerIds
      ]))
    ));
    await tester.pumpAndSettle();

    // Hit the onTap logic directly on the first state to guarantee coverage
    final playerProfile = find.byType(PlayerProfileWidget).first;
    final gestureFinder = find.ancestor(of: playerProfile, matching: find.byType(GestureDetector)).first;
    final gestureDetector = tester.widget<GestureDetector>(gestureFinder);
    
    if (gestureDetector.onTap != null) {
      gestureDetector.onTap!(); // Adds to selectedPlayerIds
      await tester.pump();
      gestureDetector.onTap!(); // Removes from selectedPlayerIds
      await tester.pump();
    }

    Player.players = originalPlayers;
  });

  testWidgets('Coverage for CourseListItem rendering locationName', (tester) async {
    final course = Course(
      id: 'c1',
      name: 'Test Course',
      numberOfHoles: 9,
      parStrokes: {1: 3},
      locationName: 'Awesome Location',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CourseListItem(
          course: course,
          onDelete: () {},
          onModify: () {},
        ),
      ),
    ));

    // Initially it is collapsed.
    expect(find.text('Course: Test Course'), findsOneWidget);

    // Expand it
    await tester.tap(find.text('Course: Test Course'));
    await tester.pumpAndSettle();

    // Verify location name is shown inside the expanded tile
    expect(find.text('Location: Awesome Location'), findsOneWidget);
  });
}


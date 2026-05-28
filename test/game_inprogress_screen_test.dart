import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/course_list_item_widget.dart';
import 'package:mini_golf_tracker/add_edit_course_screen.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    UserProvider().resetForTesting();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().setAuthInstanceForTesting(mockAuth);
    SharedPreferences.setMockInitialValues({});
    // Reset static Player list between tests
    Player.players = [];
  });

  final testPlayer1 = Player(
    id: 'p1',
    playerName: 'Test',
    nickname: 'Test',
    ownerId: 'p1',
    totalScore: 0,
    email: 'test@example.com',
  );
  final testPlayer2 = Player(
    id: 'p2',
    playerName: 'P2',
    nickname: 'P2',
    ownerId: 'p1',
    totalScore: 0,
    email: 'test2@example.com',
  );

  /// Seeds Firestore with test players and populates Player.players
  /// so that getPlayerFriendById() and updatePlayerScoreInDatabase() work.
  Future<void> seedPlayersAndLogin(
    FakeFirebaseFirestore firestore,
    Player p1,
    Player p2,
  ) async {
    await firestore.collection('players').doc(p1.id).set(p1.toJson());
    await firestore.collection('players').doc(p2.id).set(p2.toJson());
    // Login first with empty players so that adoptLocalGuestPlayers doesn't
    // treat our test players as guest players to migrate.
    await UserProvider().login(p1);
    // Set Player.players AFTER login so getPlayerFriendById() works in _updateGame.
    Player.players = [p1, p2];
  }

  Game createTestGame() {
    return Game(
      id: 'test_game_1',
      name: 'Test Game',
      course: Course(
        id: 'c1',
        name: 'Test Course',
        numberOfHoles: 2,
        parStrokes: {1: 3, 2: 3},
      ),
      players: [
        PlayerGameInfo(playerId: 'p1', gameId: 'test_game_1', scores: []),
        PlayerGameInfo(playerId: 'p2', gameId: 'test_game_1', scores: []),
      ],
      scheduledTime: DateTime.now(),
      startTime: DateTime.now(),
      status: 'started',
    );
  }

  Game createThreeHoleGameWithScoreGap() {
    return Game(
      id: 'test_game_gap',
      name: 'Test Game Gap',
      course: Course(
        id: 'c_gap',
        name: 'Gap Course',
        numberOfHoles: 3,
        parStrokes: {1: 3, 2: 3, 3: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'test_game_gap',
          scores: [2, 2],
        ),
        PlayerGameInfo(playerId: 'p2', gameId: 'test_game_gap', scores: [1]),
      ],
      scheduledTime: DateTime.now(),
      startTime: DateTime.now(),
      status: 'started',
    );
  }

  Widget createWidgetUnderTest(Game game) {
    return MaterialApp(
      home: GameInprogressScreen(currentGame: game),
    );
  }

  Widget createPushableWidgetUnderTest(Game game) {
    return MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GameInprogressScreen(currentGame: game),
              ),
            );
          },
          child: const Text('Open game'),
        ),
      ),
    );
  }

  testWidgets('renders freemium banner for guests and navigates to LoginScreen',
      (tester) async {
    final game = createTestGame();
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Playing as a Guest. Sign up to save your score to the cloud!'),
        findsOneWidget);

    await tester.tap(find
        .text('Playing as a Guest. Sign up to save your score to the cloud!'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // let transition complete

    expect(find.byType(LoginScreen), findsOneWidget);

    // Pop the LoginScreen so that FlutterLogin's internal timers get disposed.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
  });

  testWidgets('does not render freemium banner for logged-in users',
      (tester) async {
    final player = Player(
        id: 'p1',
        playerName: 'Test',
        nickname: 'Test',
        ownerId: 'p1',
        totalScore: 0,
        email: 'test@example.com');
    await UserProvider().login(player);

    final game = createTestGame();
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Playing as a Guest. Sign up to save your score to the cloud!'),
        findsNothing);
  });

  testWidgets('course card has null onDelete and onModify updates course',
      (tester) async {
    final game = createTestGame();
    Player.players = [testPlayer1, testPlayer2];

    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    final courseListItem = tester.widget<CourseListItem>(
      find.byType(CourseListItem),
    );

    // Verify onDelete is null in GameInprogressScreen's CourseListItem
    expect(courseListItem.onDelete, isNull);

    // Expand the CourseListItem ExpansionTile
    await tester.tap(find.text('Test Course'));
    await tester.pumpAndSettle();

    // Verify Delete button is hidden
    expect(find.text('Delete'), findsNothing);

    // Tap the Edit button
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify AddEditCourseScreen is pushed
    expect(find.byType(AddEditCourseScreen), findsOneWidget);

    // Pop the screen with an updated course
    final updatedCourse = Course(
      id: 'c1',
      name: 'Updated Course Name',
      numberOfHoles: 2,
      parStrokes: {1: 4, 2: 4},
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop(updatedCourse);
    await tester.pumpAndSettle();

    // Verify UI is updated with the new course name and par
    expect(find.text('Updated Course Name'), findsOneWidget);
    expect(game.course.name, 'Updated Course Name');

    // Verify SharedPreferences updated (triggers _updateGame)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(game.id), isTrue);
    final gameJson = prefs.getString(game.id);
    expect(gameJson, contains('Updated Course Name'));
  });

  testWidgets(
      'score controls cover decrement, dropdown, switch, and score gaps',
      (tester) async {
    final game = createThreeHoleGameWithScoreGap();
    Player.players = [testPlayer1, testPlayer2];

    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    expect(find.text('Current Hole # 2 (Par: 3)'), findsOneWidget);

    final state = tester
        .state<GameInprogressScreenState>(find.byType(GameInprogressScreen));
    state.currentHole = 3;

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(game.players[1].scores, [1, 0, 6]);

    await tester.tap(find.byType(DropdownButton<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    expect(game.players[1].scores, [1, 0, 4]);

    await tester.tap(find.byIcon(Icons.remove).last);
    await tester.pumpAndSettle();
    expect(game.players[1].scores, [1, 0, 3]);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(game.players[1].scores, [1, 0, 6]);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(game.players[1].scores, [1, 0, 1]);
  });

  testWidgets('remove score button sets a blank score to one', (tester) async {
    final game = createTestGame();
    Player.players = [testPlayer1, testPlayer2];

    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();

    expect(game.players[0].scores, [1]);
  });

  testWidgets('completed current-hole button opens game details',
      (tester) async {
    final game = createTestGame();
    Player.players = [testPlayer1, testPlayer2];

    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    final state = tester
        .state<GameInprogressScreenState>(find.byType(GameInprogressScreen));
    state.gameCompleted = true;

    await tester.tap(find.text('Next Hole'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
  });

  testWidgets('popping the screen saves the current game', (tester) async {
    final game = createTestGame();
    Player.players = [testPlayer1, testPlayer2];

    await tester.pumpWidget(createPushableWidgetUnderTest(game));
    await tester.tap(find.text('Open game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(game.id), isTrue);
    expect(find.text('Open game'), findsOneWidget);
  });

  testWidgets('AppBar popup menu: Pause Game', (tester) async {
    final game = createTestGame();
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pause Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('AppBar popup menu: Abandon Game', (tester) async {
    final game = createTestGame();
    SharedPreferences.setMockInitialValues(
        {'test_game_1': jsonEncode(game.toJson())});
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abandon Game'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Strict data-loss warning. All progress will be lost.'),
        findsOneWidget);

    // Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(GameInprogressScreen), findsOneWidget);

    // Abandon
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandon Game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandon Game').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomePage), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('test_game_1'), false);
  });

  testWidgets('AppBar popup menu: End Game Early', (tester) async {
    MainScaffold.skipPrecacheForTesting = true;
    await seedPlayersAndLogin(fakeFirestore, testPlayer1, testPlayer2);

    final game = createTestGame();
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('End Game Early'));
    await tester.pumpAndSettle();

    // Verify dialog
    expect(find.text('Scores will be finalized and cannot be reopened.'),
        findsOneWidget);

    // Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Pause Game instead
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game Early'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause Game instead'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('AppBar popup menu: End Game Early - End Game', (tester) async {
    await seedPlayersAndLogin(fakeFirestore, testPlayer1, testPlayer2);

    final game = createTestGame();
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game Early'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
    expect(game.status, 'completed');
  });

  testWidgets('Score assignment: incomplete holes get max score 6',
      (tester) async {
    await seedPlayersAndLogin(fakeFirestore, testPlayer1, testPlayer2);

    final game = createTestGame(); // 2 holes
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    // Change score for player 1 to 2
    final addIcon = find.byIcon(Icons.add);
    await tester.tap(addIcon.first); // increments from 0 to 1
    await tester.pumpAndSettle();
    await tester.tap(addIcon.first); // increments from 1 to 2
    await tester.pumpAndSettle();

    // Player 2 leaves score at 0.
    await tester.tap(find.text('Next Hole'));
    await tester.pumpAndSettle();

    expect(find.text('Current Hole # 2 (Par: 3)'), findsOneWidget);

    // Complete game
    await tester.tap(find.text('Complete Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(PastGameDetailsScreen), findsOneWidget);

    // Player 1 had 2 on hole 1, and 0 on hole 2 → 2 + 6 = 8
    // Player 2 had 0 on hole 1, and 0 on hole 2 → 6 + 6 = 12
    expect(game.players[0].totalScore, 8);
    expect(game.players[1].totalScore, 12);
  });

  testWidgets('Previous Hole navigation', (tester) async {
    final game = createTestGame(); // 2 holes
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next Hole'));
    await tester.pumpAndSettle();

    expect(find.text('Current Hole # 2 (Par: 3)'), findsOneWidget);

    await tester.tap(find.text('Prev Hole'));
    await tester.pumpAndSettle();

    expect(find.text('Current Hole # 1 (Par: 3)'), findsOneWidget);
  });

  testWidgets('Complete game without modifying any score sets all to 6',
      (tester) async {
    await seedPlayersAndLogin(fakeFirestore, testPlayer1, testPlayer2);

    final game = createTestGame(); // 2 holes
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next Hole'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
    expect(game.players[0].totalScore, 12); // 6 * 2
  });

  testWidgets('Complete game sets 0 score for existing hole to 6',
      (tester) async {
    await seedPlayersAndLogin(fakeFirestore, testPlayer1, testPlayer2);

    final game = createTestGame(); // 2 holes
    // pre-populate length to test the second condition of OR (pgi.scores[currentHole - 1] == 0)
    game.players[0].scores = [0, 0];
    game.players[1].scores = [0, 0];

    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Complete Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
    expect(game.players[0].totalScore, 6); // 0 + 6
  });

  testWidgets('coach mark appears on resume and disappears on tap',
      (tester) async {
    final game = createTestGame();
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    final state = tester
        .state<GameInprogressScreenState>(find.byType(GameInprogressScreen));

    // Simulate app resuming
    state.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text("Need a break? You can safely pause your game here!"),
        findsOneWidget);

    // Tap to dismiss
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text("Need a break? You can safely pause your game here!"),
        findsNothing);
  });

  testWidgets('coach mark appears after dynamic idle timer', (tester) async {
    final game = createTestGame(); // 2 players, so timer is 2 * 3 = 6 minutes
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    expect(find.text("Need a break? You can safely pause your game here!"),
        findsNothing);

    // Pump less than 6 minutes
    await tester.pump(const Duration(minutes: 5));
    expect(find.text("Need a break? You can safely pause your game here!"),
        findsNothing);

    // Pump enough to cross 6 minutes
    await tester.pump(const Duration(minutes: 2));
    expect(find.text("Need a break? You can safely pause your game here!"),
        findsOneWidget);
  });

  testWidgets('interaction resets the idle timer', (tester) async {
    final game = createTestGame(); // 6 min timer
    await tester.pumpWidget(createWidgetUnderTest(game));
    await tester.pumpAndSettle();

    // Pump 4 minutes
    await tester.pump(const Duration(minutes: 4));

    // Interact to reset
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Pump another 4 minutes (total 8 from start)
    await tester.pump(const Duration(minutes: 4));
    
    // Coach mark should not appear because timer reset
    expect(find.text("Need a break? You can safely pause your game here!"),
        findsNothing);

    // Pump 3 more minutes to cross the new 6-minute threshold
    await tester.pump(const Duration(minutes: 3));
    expect(find.text("Need a break? You can safely pause your game here!"),
        findsOneWidget);
  });
}

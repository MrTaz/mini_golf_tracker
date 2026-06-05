import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game_create_screen.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Player _guestPlayer(String id, String nickname) => Player(
      id: id,
      playerName: '$nickname Guest',
      nickname: nickname,
      ownerId: 'guest',
      totalScore: 0,
    );

Player _authPlayer() => Player(
      id: 'auth-uid',
      playerName: 'Jane Doe',
      nickname: 'Jane',
      ownerId: 'auth-uid',
      totalScore: 0,
      email: 'jane@example.com',
    );

Course _fakeCourse({String id = 'c1', String name = 'Windy Hills'}) => Course(
      id: id,
      name: name,
      numberOfHoles: 9,
      parStrokes: {1: 3, 2: 4, 3: 3, 4: 4, 5: 3, 6: 4, 7: 3, 8: 4, 9: 3},
    );

/// Pumps [GameCreateScreen] wrapped in a simple [MaterialApp].
Future<void> pumpCreateScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: GameCreateScreen()));
  await tester.pump();
}

/// Pumps [GameCreateScreen] via a parent-button push so the state can be
/// accessed. Returns the [GameCreateScreenState].
Future<GameCreateScreenState> pushAndGetState(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => Navigator.push<void>(
            ctx,
            MaterialPageRoute(builder: (_) => const GameCreateScreen()),
          ),
          child: const Text('Go'),
        );
      }),
    ),
  );
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
  return tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
      _guestPlayer('p3', 'Charlie'),
      _guestPlayer('p4', 'Dave'),
      _guestPlayer('p5', 'Eve'),
      _guestPlayer('p6', 'Frank'),
      _guestPlayer('p7', 'Grace'),
    ];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    Player.players = [];
    UserProvider().resetForTesting();
  });

  // ─── 1. Initial UI rendering ────────────────────────────────────────────

  testWidgets('renders all form fields and Create Game button for guest',
      (tester) async {
    await pumpCreateScreen(tester);

    expect(find.text('Create Game'), findsWidgets); // AppBar title + button
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Course'), findsOneWidget);
    expect(find.text('Select a course'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('0 players selected'), findsOneWidget);
    expect(find.text('Start Time'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('course and player actions render as Material 3 selection cards',
      (tester) async {
    await pumpCreateScreen(tester);

    expect(
      find.ancestor(of: find.text('Course'), matching: find.byType(ListTile)),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('Players'), matching: find.byType(ListTile)),
      findsNothing,
    );
    expect(find.byType(AnimatedContainer), findsNWidgets(2));

    final courseCard = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Course'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = courseCard.decoration! as BoxDecoration;

    expect(courseCard.duration, const Duration(milliseconds: 250));
    expect(decoration.borderRadius, BorderRadius.circular(16.0));
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('selected cards use highlighted Material 3 styling',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    await tester.pump();

    final courseCard = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Windy Hills'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = courseCard.decoration! as BoxDecoration;

    expect(decoration.color, Colors.green.shade50);
    expect(decoration.border, isA<Border>());
  });

  testWidgets('renders edit icon for Start Time when user is authenticated',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    await pumpCreateScreen(tester);

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('player count subtitle shows singular "player" when 1 selected',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedPlayersForTesting([_guestPlayer('p1', 'Ava')]);
    await tester.pump();
    expect(find.text('1 player selected'), findsOneWidget);
  });

  testWidgets('course subtitle shows course name after course selected',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    await tester.pump();
    expect(find.text('Windy Hills'), findsOneWidget);
  });

  testWidgets('player count subtitle shows plural "players" by default',
      (tester) async {
    await pumpCreateScreen(tester);
    expect(find.text('0 players selected'), findsOneWidget);
  });

  testWidgets('player count subtitle shows plural "players" when 2 selected',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    await tester.pump();
    expect(find.text('2 players selected'), findsOneWidget);
  });

  // ─── 2. Form validation ──────────────────────────────────────────────────

  testWidgets('shows validation error when game name is empty', (tester) async {
    await pumpCreateScreen(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump();
    expect(find.text('Please enter a game name'), findsOneWidget);
  });

  testWidgets('shows validation error when game name is only whitespace',
      (tester) async {
    await pumpCreateScreen(tester);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump();
    expect(find.text('Please enter a game name'), findsOneWidget);
  });

  testWidgets('shows snack bar when no course selected', (tester) async {
    await pumpCreateScreen(tester);
    await tester.enterText(find.byType(TextFormField), 'My Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump();
    expect(find.text('Please select a course'), findsOneWidget);
  });

  testWidgets('shows snack bar when fewer than 2 players selected',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([_guestPlayer('p1', 'Ava')]);
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'My Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump();

    expect(find.text('Please select between 2 and 6 players'), findsOneWidget);
  });

  testWidgets('shows snack bar when more than 6 players selected',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting(
        List.generate(7, (i) => _guestPlayer('p$i', 'Player $i')));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'My Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump();

    expect(find.text('Please select between 2 and 6 players'), findsOneWidget);
  });

  // ─── 3. Successful game creation ─────────────────────────────────────────

  testWidgets(
      'creates game and navigates to GameInprogressScreen with 2 players',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Test Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  testWidgets('creates game with exactly 6 players (upper boundary)',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting(
        List.generate(6, (i) => _guestPlayer('p$i', 'Player $i')));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Six Player Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  testWidgets('shows success snackbar before navigating to game in progress',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Game With Snackbar');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump(); // single pump — snackbar visible before navigation

    expect(find.text('Game created successfully'), findsOneWidget);
  });

  testWidgets('guest user: scheduledTime is reset to now before creating game',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    state.setScheduledTimeForTesting(DateTime(2099, 1, 1));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Guest Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);

    // Confirm scheduled time was NOT written as 2099 (it was reset to now)
    final prefs = await SharedPreferences.getInstance();
    final gameJson = prefs.getString(prefs.getKeys().first);
    expect(gameJson, isNotNull);
    expect(gameJson!.contains('2099'), isFalse);
  });

  testWidgets('shows warning dialog when active game exists and cancel stops creation',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    
    // Create an active game in SharedPreferences
    final game = Game(
      id: 'active_game',
      name: 'Active Game',
      course: _fakeCourse(),
      players: [],
      scheduledTime: DateTime.now(),
      status: 'started',
    );
    SharedPreferences.setMockInitialValues({'active_game': jsonEncode(game.toJson())});

    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Test Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsNothing);
  });

  testWidgets('shows warning dialog when active game exists and continue creates game',
      (tester) async {
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    
    // Create an active game in SharedPreferences
    final game = Game(
      id: 'active_game',
      name: 'Active Game',
      course: _fakeCourse(),
      players: [],
      scheduledTime: DateTime.now(),
      status: 'started',
    );
    SharedPreferences.setMockInitialValues({'active_game': jsonEncode(game.toJson())});

    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Test Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  testWidgets('shows scheduling conflict dialog and cancel stops creation',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    
    // Need to set fake Firestore with an unstarted game within 2 hours
    final conflictGame = Game(
      id: 'conflict_game',
      name: 'Conflict Game',
      course: _fakeCourse(),
      players: [PlayerGameInfo(playerId: 'auth-uid', gameId: 'conflict_game', scores: [])],
      scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
      status: 'unstarted_game',
    );
    await DatabaseConnection.client.collection('games').doc(conflictGame.id).set({
      ...conflictGame.toJson(),
      'participant_ids': ['auth-uid'],
    });
    await DatabaseConnection.client.collection('player_game_info').doc('${conflictGame.id}_auth-uid').set({
      'game_id': conflictGame.id,
      'player_id': 'auth-uid',
    });

    state.setScheduledTimeForTesting(DateTime.now());
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Test Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduling Conflict'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsNothing);
  });

  testWidgets('shows scheduling conflict dialog and double-book creates game',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    
    // Need to set fake Firestore with an unstarted game within 2 hours
    final conflictGame = Game(
      id: 'conflict_game2',
      name: 'Conflict Game 2',
      course: _fakeCourse(),
      players: [PlayerGameInfo(playerId: 'auth-uid', gameId: 'conflict_game2', scores: [])],
      scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
      status: 'unstarted_game',
    );
    await DatabaseConnection.client.collection('games').doc(conflictGame.id).set({
      ...conflictGame.toJson(),
      'participant_ids': ['auth-uid'],
    });
    await DatabaseConnection.client.collection('player_game_info').doc('${conflictGame.id}_auth-uid').set({
      'game_id': conflictGame.id,
      'player_id': 'auth-uid',
    });

    state.setScheduledTimeForTesting(DateTime.now());
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Test Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.text('Double-Book'), findsOneWidget);
    await tester.tap(find.text('Double-Book'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  // ─── 4. Course selection guard logic ─────────────────────────────────────

  testWidgets('handleCourseSelectionResult with non-null updates course',
      (tester) async {
    await pumpCreateScreen(tester);
    final state =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    state.handleCourseSelectionResult(_fakeCourse());
    await tester.pump();
    expect(find.text('Windy Hills'), findsOneWidget);
  });

  testWidgets('handleCourseSelectionResult with null keeps no course selected',
      (tester) async {
    await pumpCreateScreen(tester);
    final state =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    state.handleCourseSelectionResult(null);
    await tester.pump();
    expect(find.text('Select a course'), findsOneWidget);
  });

  testWidgets('tapping Course selection card triggers _selectCourse navigation',
      (tester) async {
    // Use navigatorKey so we can pop immediately after the push starts,
    // verifying the navigation path is exercised without building CoursesScreen.
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const GameCreateScreen(),
    ));
    await tester.pump();

    await tester.tap(find.text('Select a course'));
    await tester.pump(); // Process tap — push starts

    // Immediately pop with a selected course
    navKey.currentState!.pop(_fakeCourse());
    await tester.pumpAndSettle();

    expect(find.text('Windy Hills'), findsOneWidget);
  });

  testWidgets('handleCourseSelectionResult with empty course clears selection',
      (tester) async {
    await pumpCreateScreen(tester);
    final state =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    
    // First select a course
    state.handleCourseSelectionResult(_fakeCourse());
    await tester.pump();
    expect(find.text('Windy Hills'), findsOneWidget);

    // Now select Course.empty()
    state.handleCourseSelectionResult(Course.empty());
    await tester.pump();
    expect(find.text('Select a course'), findsOneWidget);
  });

  testWidgets('returning Course.empty() from navigation clears selection',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const GameCreateScreen(),
    ));
    await tester.pump();

    // 1. Initial state has no course selection
    expect(find.text('Select a course'), findsOneWidget);

    // 2. Select course
    await tester.tap(find.text('Select a course'));
    await tester.pump(); // push starts
    navKey.currentState!.pop(_fakeCourse());
    await tester.pumpAndSettle();
    expect(find.text('Windy Hills'), findsOneWidget);

    // 3. Select course again but return Course.empty()
    await tester.tap(find.text('Windy Hills'));
    await tester.pump(); // push starts
    navKey.currentState!.pop(Course.empty());
    await tester.pumpAndSettle();
    expect(find.text('Select a course'), findsOneWidget);
  });

  testWidgets('tapping Course selection card dismisses game name focus',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const GameCreateScreen(),
    ));
    await tester.pump();

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Select a course'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );

    navKey.currentState!.pop(_fakeCourse());
    await tester.pumpAndSettle();
  });

  // ─── 5. Player selection guard logic ─────────────────────────────────────

  testWidgets('handlePlayersSelectionResult with non-empty list updates count',
      (tester) async {
    await pumpCreateScreen(tester);
    final state =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    state.handlePlayersSelectionResult([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    await tester.pump();
    expect(find.text('2 players selected'), findsOneWidget);
  });

  testWidgets('handlePlayersSelectionResult with null keeps old selection',
      (tester) async {
    await pumpCreateScreen(tester);
    final state =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    state.handlePlayersSelectionResult(null);
    await tester.pump();
    expect(find.text('0 players selected'), findsOneWidget);
  });

  testWidgets(
      'handlePlayersSelectionResult with empty list keeps old selection',
      (tester) async {
    await pumpCreateScreen(tester);
    final state =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    state.handlePlayersSelectionResult([]);
    await tester.pump();
    expect(find.text('0 players selected'), findsOneWidget);
  });

  testWidgets(
      'tapping Players selection card triggers _selectPlayers navigation',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const GameCreateScreen(),
    ));
    await tester.pump();

    await tester.tap(find.text('Players'));
    await tester.pump(); // Process tap — push starts

    // Immediately pop with selected players
    navKey.currentState!.pop([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('2 players selected'), findsOneWidget);
  });

  testWidgets('tapping Create Game dismisses game name focus', (tester) async {
    await pumpCreateScreen(tester);

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    expect(find.text('Please enter a game name'), findsOneWidget);
  });

  // ─── 6. Gated scheduling dialog (guest) ──────────────────────────────────

  testWidgets('tapping Start Time as guest shows gated scheduling dialog',
      (tester) async {
    await pumpCreateScreen(tester);

    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduling is Gated'), findsOneWidget);
    expect(find.textContaining('To schedule games in advance'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Log In / Sign Up'), findsOneWidget);
  });

  testWidgets('gated dialog Cancel closes dialog without navigation',
      (tester) async {
    await pumpCreateScreen(tester);

    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduling is Gated'), findsNothing);
    expect(find.byType(GameCreateScreen), findsOneWidget);
  });

  testWidgets(
      'gated dialog Log In / Sign Up dismisses dialog and initiates navigation',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const GameCreateScreen(),
    ));
    await tester.pump();

    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduling is Gated'), findsOneWidget);

    // Tap button — dialog pops and LoginScreen push starts.
    await tester.tap(find.text('Log In / Sign Up'));
    // Use timed pumps to advance fake-async clock through the dialog close
    // animation without waiting for the flutter_login 1-second timer.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    // Dialog must be gone after animation completes.
    expect(find.text('Scheduling is Gated'), findsNothing);

    // Pop LoginScreen so its widget is unmounted.
    if (navKey.currentState?.canPop() == true) {
      navKey.currentState!.pop();
    }
    // Advance fake time past flutter_login's 1-second initState timer so it
    // fires (and is silently ignored on the unmounted widget) before test end.
    await tester.pump(const Duration(seconds: 2));
  });

  // ─── 7. Date/time picker (authenticated user) ────────────────────────────

  testWidgets('authenticated user: tapping Start Time shows date picker',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    await pumpCreateScreen(tester);
    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets(
      'authenticated user: cancelling date picker leaves scheduledTime unchanged',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    await pumpCreateScreen(tester);

    final startTimeTile = find.ancestor(
      of: find.text('Start Time'),
      matching: find.byType(ListTile),
    );
    final allTexts = tester
        .widgetList<Text>(
            find.descendant(of: startTimeTile, matching: find.byType(Text)))
        .toList();
    final initialSubtitle = allTexts.length > 1 ? allTexts[1].data ?? '' : '';

    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text(initialSubtitle), findsOneWidget);
  });

  testWidgets(
      'authenticated user: selecting date then cancelling time picker leaves scheduledTime unchanged',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    await pumpCreateScreen(tester);

    final startTimeTile = find.ancestor(
      of: find.text('Start Time'),
      matching: find.byType(ListTile),
    );
    final allTexts = tester
        .widgetList<Text>(
            find.descendant(of: startTimeTile, matching: find.byType(Text)))
        .toList();
    final initialSubtitle = allTexts.length > 1 ? allTexts[1].data ?? '' : '';

    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    // Confirm date picker
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Cancel time picker
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text(initialSubtitle), findsOneWidget);
  });

  testWidgets(
      'authenticated user: selecting date and time updates scheduledTime display',
      (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    await pumpCreateScreen(tester);

    await tester.tap(find.text('Start Time'));
    await tester.pumpAndSettle();

    // Confirm date
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Confirm time
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Start Time'), findsOneWidget);
  });

  testWidgets('authenticated user: schedules game in the future, sets unstarted_game status and pops to dashboard', (tester) async {
    UserProvider().loggedInUser = _authPlayer();
    final state = await pushAndGetState(tester);
    state.setSelectedCourseForTesting(_fakeCourse());
    state.setSelectedPlayersForTesting([
      _guestPlayer('p1', 'Ava'),
      _guestPlayer('p2', 'Ben'),
    ]);

    final futureTime = DateTime.now().add(const Duration(hours: 3));
    state.setScheduledTimeForTesting(futureTime);
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Future Scheduled Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameCreateScreen), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k != 'email' && k != 'loggedInUser' && k != 'courses' && k != 'guest_players');
    expect(keys.length, 1);
    final savedJson = prefs.getString(keys.first);
    expect(savedJson, isNotNull);
    final savedMap = jsonDecode(savedJson!) as Map<String, dynamic>;
    expect(savedMap['status'], 'unstarted_game');
    expect(savedMap['name'], 'Future Scheduled Game');

    final doc = await DatabaseConnection.client.collection('games').doc(savedMap['id']).get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['status'], 'unstarted_game');
    expect(doc.data()?['name'], 'Future Scheduled Game');
  });
}

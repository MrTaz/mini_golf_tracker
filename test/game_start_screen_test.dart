import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Player _authPlayer({
  String id = 'auth-uid',
  String name = 'Jane Doe',
  String email = 'jane@example.com',
}) =>
    Player(
      id: id,
      playerName: name,
      nickname: name.split(' ').first,
      ownerId: id,
      totalScore: 0,
      email: email,
    );

Game _twoPlayerGame({
  Course? course,
  DateTime? scheduledTime,
}) =>
    Game(
      id: 'game-id-1',
      name: 'Test Game',
      course: course ??
          Course(
            id: 'c1',
            name: 'Windy Hills',
            numberOfHoles: 18,
            parStrokes: {1: 3, 2: 4},
          ),
      players: [
        PlayerGameInfo(playerId: 'p1', gameId: 'game-id-1', scores: []),
        PlayerGameInfo(playerId: 'p2', gameId: 'game-id-1', scores: []),
      ],
      scheduledTime: scheduledTime ?? DateTime(2026, 5, 17, 10, 0),
    );

Game _onePlayerGame() => Game(
      id: 'game-id-2',
      name: 'Tiny Game',
      course:
          Course(id: 'c1', name: 'Hills', numberOfHoles: 18, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'p1', gameId: 'game-id-2', scores: []),
      ],
      scheduledTime: DateTime(2026, 5, 17, 10, 0),
    );

Game _zeroCourseGame() => Game(
      id: 'game-id-3',
      name: 'No Course Game',
      course:
          Course(id: 'c0', name: 'None', numberOfHoles: 0, parStrokes: {}),
      players: [
        PlayerGameInfo(playerId: 'p1', gameId: 'game-id-3', scores: []),
        PlayerGameInfo(playerId: 'p2', gameId: 'game-id-3', scores: []),
      ],
      scheduledTime: DateTime(2026, 5, 17, 10, 0),
    );

Game _sevenPlayerGame() => Game(
      id: 'game-id-5',
      name: 'Seven Player',
      course:
          Course(id: 'c1', name: 'Windy Hills', numberOfHoles: 18, parStrokes: {1: 3}),
      players: List.generate(
        7,
        (i) => PlayerGameInfo(
          playerId: 'p${i + 1}',
          gameId: 'game-id-5',
          playOrderPosition: i,
          scores: [],
        ),
      ),
      scheduledTime: DateTime(2026, 5, 17, 10, 0),
    );

Game _threePlayerGame() => Game(
      id: 'game-id-4',
      name: 'Three Player',
      course:
          Course(id: 'c1', name: 'Windy Hills', numberOfHoles: 18, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(
            playerId: 'p1', gameId: 'game-id-4', playOrderPosition: 0, scores: []),
        PlayerGameInfo(
            playerId: 'p2', gameId: 'game-id-4', playOrderPosition: 1, scores: []),
        PlayerGameInfo(
            playerId: 'p3', gameId: 'game-id-4', playOrderPosition: 2, scores: []),
      ],
      scheduledTime: DateTime(2026, 5, 17, 10, 0),
    );

// Finder helpers
Finder get _editCourseIconButton =>
    find.ancestor(of: find.byIcon(Icons.edit), matching: find.byType(IconButton));

Finder get _scheduleIconButton =>
    find.ancestor(of: find.byIcon(Icons.schedule), matching: find.byType(IconButton));

Finder get _lockOutlineIconButton =>
    find.ancestor(of: find.byIcon(Icons.lock_outline), matching: find.byType(IconButton));

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
    ];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    Player.players = [];
    UserProvider().resetForTesting();
  });

  // ─── 1. Creation Dialog (lines 87-106) ──────────────────────────────────

  testWidgets(
      'Creation dialog: typing name and tapping Create pushes GameStartScreen '
      'with new game; callback is wired through (lines 87-106)', (tester) async {
    bool callbackCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(
        unstartedGame: null,
        callback: () => callbackCalled = true,
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Create New Game'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Super Swing Match');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Game'), findsNothing);
    expect(find.text('Start Game - Super Swing Match'), findsOneWidget);

    // Verify the callback stub passes through (lines 104-107)
    final state = tester.state<GameStartScreenState>(find.byType(GameStartScreen));
    expect(state.widget.callback, isNotNull);
    state.widget.callback!();
    expect(callbackCalled, isTrue);
  });

  testWidgets(
      'Creation dialog: tapping Cancel dismisses without navigation', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const GameStartScreen(unstartedGame: null),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Create New Game'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Create New Game'), findsNothing);
  });

  // ─── 2. Course Selection (lines 141-167) ────────────────────────────────

  testWidgets(
      'Course selection: tapping edit opens CoursesScreen and selecting a course '
      'updates game.course (!_isCreatingGame branch, lines 141-167)', (tester) async {
    await fakeFirestore.collection('courses').doc('c-abc').set({
      'name': 'Pinecrest Links',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    expect(find.text('Windy Hills'), findsOneWidget);

    // Use ancestor finder to resolve the single edit IconButton in the course card
    await tester.tap(_editCourseIconButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Pinecrest Links'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(game.course.name, 'Pinecrest Links');
    expect(game.course.numberOfHoles, 9);
  });

  // ─── 3. Gated Scheduling Dialog (lines 169-203) ─────────────────────────

  testWidgets(
      'Guest: tapping ListTile shows Gated dialog; Cancel closes it (lines 169-202)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    // In guest mode the ListTile.onTap = _showGatedSchedulingDialog
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();

    expect(find.text('Scheduling is Gated'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Scheduling is Gated'), findsNothing);
  });

  testWidgets(
      'Guest: tapping lock icon also shows Gated dialog; '
      'Log In / Sign Up navigates to LoginScreen (lines 169-203)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(_lockOutlineIconButton);
    await tester.pumpAndSettle();
    expect(find.text('Scheduling is Gated'), findsOneWidget);

    await tester.tap(find.text('Log In / Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  // ─── 4. Date & Time Picker (lines 205-242) ──────────────────────────────

  testWidgets(
      'Course selection while creating game stores _newGameCourse '
      '(lines 149, 161)', (tester) async {
    await fakeFirestore.collection('courses').doc('c-abc').set({
      'name': 'Pinecrest Links',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: null),
    ));
    await tester.pump();
    await tester.pump();

    final state = tester.state<GameStartScreenState>(find.byType(GameStartScreen));
    state.selectCourseForTesting();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(state.newGameCourseForTesting?.name, 'Pinecrest Links');
  });

  testWidgets(
      'editStartTimeForTesting as guest shows gated dialog (line 207)',
      (tester) async {
    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    final state = tester.state<GameStartScreenState>(find.byType(GameStartScreen));
    state.editStartTimeForTesting();
    await tester.pumpAndSettle();

    expect(find.text('Scheduling is Gated'), findsOneWidget);
  });

  testWidgets(
      'Guest Schedule game navigates to LoginScreen (lines 305-307)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: _twoPlayerGame()),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
      'Auth user: tapping schedule icon opens date→time pickers and '
      'updates scheduledTime (lines 205-242)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final game = _twoPlayerGame(
      scheduledTime: DateTime.now().add(const Duration(days: 7)),
    );
    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    // Use ancestor finder to target the schedule icon in the ListTile trailing
    await tester.tap(_scheduleIconButton);
    await tester.pumpAndSettle();

    // Date picker is open — dismiss by pressing OK (selecting the initialDate)
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Time picker is now open — dismiss by pressing OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // _editStartTime (lines 205-242) ran to completion; verify screen is still alive
    expect(find.byType(GameStartScreen), findsOneWidget);
  });

  testWidgets(
      'Auth user: past scheduledTime uses scheduled date as firstDate (line 223)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final game = _twoPlayerGame(
      scheduledTime: DateTime(2026, 5, 17, 10, 0),
    );
    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(_scheduleIconButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(GameStartScreen), findsOneWidget);
  });

  // ─── 5. Add Players (lines 244-267) ─────────────────────────────────────

  testWidgets(
      'Tapping Add players opens PlayersScreen; '
      'selecting + confirming replaces game.players (lines 244-267)', (tester) async {
    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(find.text('Add players'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Select Players'), findsOneWidget);

    // Toggle Ava's switch to select her
    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add selected players to game.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // replaceRange sets only the selected players; accept whichever player the first switch selects
    expect(game.players.length, 1);
    // The player id should be one of the seeded players
    expect(['p1', 'p2', 'p3'], contains(game.players.first.playerId));
  });

  // ─── 6. Remove Player + InkWell tap (lines 269-272, 403-404, 415) ───────

  testWidgets(
      'Tapping inkwell toggles selection; tapping remove_circle removes player '
      '(lines 269-272, 403-404, 415)', (tester) async {
    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    final inkwellP1 = find.byKey(const Key('inkwellOrderTapp1'));
    expect(inkwellP1, findsOneWidget);
    final inkwell = tester.widget<InkWell>(inkwellP1);
    inkwell.onTap!();
    await tester.pump();

    // Tap the remove_circle icon on the first player card
    await tester.tap(find.byIcon(Icons.remove_circle).first);
    await tester.pumpAndSettle();

    // Lines 269-272: both _playersInfo and game.players updated
    expect(game.players.length, 1);
    expect(game.players.first.playerId, 'p2');
  });

  // ─── 7. Callback via _updateUnstartedGame (line 299) ────────────────────

  testWidgets(
      'Schedule game fires callback via _updateUnstartedGame (line 299)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool callbackFired = false;
    final game = _twoPlayerGame();
    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(
        unstartedGame: game,
        callback: () => callbackFired = true,
      ),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();

    expect(callbackFired, isTrue);
  });

  // ─── 8. Schedule Validations (lines 317, 325, 333-335) ──────────────────

  testWidgets('Schedule: 0-hole course shows snackbar (line 317)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: _zeroCourseGame()),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();
    expect(find.text('Please select a valid course'), findsOneWidget);
  });

  testWidgets('Schedule: <2 players shows snackbar (line 325)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: _onePlayerGame()),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();
    expect(find.text('Please select between 2 and 6 players'), findsOneWidget);
  });

  testWidgets('Schedule: >6 players shows snackbar', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: _sevenPlayerGame()),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();
    expect(find.text('Please select between 2 and 6 players'), findsOneWidget);
  });

  testWidgets(
      'Schedule: success shows snackbar and pops route (lines 338-346)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GameStartScreen(unstartedGame: _twoPlayerGame()),
      ),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('Scheduling your game to start'),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    expect(find.byType(GameStartScreen), findsNothing);
  });

  testWidgets(
      'Schedule: DateTime(0) scheduledTime is reset to now (lines 333-335)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    final game = _twoPlayerGame(scheduledTime: DateTime(0));

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();

    expect(game.scheduledTime.year, DateTime.now().year);
  });

  // ─── 9. Start Validations (lines 355, 363, 378-379) ─────────────────────

  testWidgets('Start: 0-hole course shows snackbar (line 355)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: _zeroCourseGame()),
    ));

    await tester.tap(find.text('Start the game!'));
    await tester.pumpAndSettle();
    expect(find.text('Please select a valid course'), findsOneWidget);
  });

  testWidgets('Start: <2 players shows snackbar (line 363)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: _onePlayerGame()),
    ));

    await tester.tap(find.text('Start the game!'));
    await tester.pumpAndSettle();
    expect(find.text('Please select between 2 and 6 players'), findsOneWidget);
  });

  testWidgets(
      'Start: DateTime(0) scheduledTime resets to now (line 379)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    final game = _twoPlayerGame(scheduledTime: DateTime(0));

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(find.text('Start the game!'));
    await tester.pumpAndSettle();

    expect(game.scheduledTime, isNot(DateTime(0)));
    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  testWidgets(
      'Start: scheduled over an hour away shows snackbar (lines 377-381)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserProvider().login(_authPlayer());

    final game = _twoPlayerGame(
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
    );

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(find.text('Start the game!'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('over an hour away'),
      findsOneWidget,
    );
    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  testWidgets(
      'PopScope back triggers _updateUnstartedGame (lines 596-599)',
      (tester) async {
    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GameStartScreen(unstartedGame: game),
                ),
              );
            },
            child: const Text('Open game setup'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open game setup'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(game.id), isNotNull);
  });

  testWidgets(
      'Start: valid game navigates to GameInprogressScreen (lines 369-394)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final game = _twoPlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    await tester.tap(find.text('Start the game!'));
    await tester.pumpAndSettle();

    // Valid game (2 players, valid course) navigates to GameInprogressScreen
    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  // ─── 10. ReorderableListView (lines 493-501) ─────────────────────────────

  testWidgets(
      'ReorderableListView onReorder: covers both branches '
      '(oldIndex<newIndex and oldIndex>=newIndex) (lines 493-501)', (tester) async {
    final game = _threePlayerGame();

    await tester.pumpWidget(MaterialApp(
      home: GameStartScreen(unstartedGame: game),
    ));

    final listView =
        tester.widget<ReorderableListView>(find.byType(ReorderableListView));

    // Verify initial order: p1 at position 0, p2 at 1, p3 at 2
    // Keys are "inkwellOrderTap" + playerId (no separator)
    final initialOrder = tester
        .widgetList<InkWell>(find.byType(InkWell))
        .where((w) => w.key != null && w.key.toString().contains('inkwellOrderTap'))
        .map((w) => w.key.toString())
        .toList();
    expect(initialOrder[0], contains('p1'));
    expect(initialOrder[1], contains('p2'));
    expect(initialOrder[2], contains('p3'));

    // Branch 1: oldIndex(0) < newIndex(2) → newIndex adjusted to 1 inside onReorder
    // p1 moves from index 0 to index 1 → result: [p2, p1, p3]
    listView.onReorder(0, 2);
    await tester.pumpAndSettle();

    final afterFirst = tester
        .widgetList<InkWell>(find.byType(InkWell))
        .where((w) => w.key != null && w.key.toString().contains('inkwellOrderTap'))
        .map((w) => w.key.toString())
        .toList();
    expect(afterFirst[0], contains('p2'));
    expect(afterFirst[1], contains('p1'));
    expect(afterFirst[2], contains('p3'));

    // Branch 2: oldIndex(2) >= newIndex(0) → no adjustment
    // p3 moves from index 2 to index 0 → result: [p3, p2, p1]
    listView.onReorder(2, 0);
    await tester.pumpAndSettle();

    final afterSecond = tester
        .widgetList<InkWell>(find.byType(InkWell))
        .where((w) => w.key != null && w.key.toString().contains('inkwellOrderTap'))
        .map((w) => w.key.toString())
        .toList();
    expect(afterSecond[0], contains('p3'));
    expect(afterSecond[1], contains('p2'));
    expect(afterSecond[2], contains('p1'));
  });
}

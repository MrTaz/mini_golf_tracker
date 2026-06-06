import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/widgets/app_drawer_widget.dart';
import 'package:mini_golf_tracker/features/courses/data/models/course.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_create_screen.dart';
import 'package:mini_golf_tracker/features/gameplay/presentation/screens/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_start_screen.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/dashboard_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/past_game_details_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/past_games_screen.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/players/presentation/widgets/player_avatar_widget.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';
import 'package:mini_golf_tracker/features/players/presentation/screens/players_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/scheduled_games_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/main.dart';
import '../../../../test_helper.dart';

void main() {
  setUp(() {
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(MockFirebaseAuth());
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    SharedPreferences.setMockInitialValues({});
    Player.players = [];
    MainScaffold.skipPrecacheForTesting = true;
  });

  Game makeGame(
    String id,
    String status, {
    DateTime? scheduledTime,
    DateTime? completedTime,
    bool useDefaultCompletedTime = true,
    int totalScore = 0,
  }) {
    return Game(
      id: id,
      name: '$status game',
      course: Course(
        id: 'c1',
        name: 'Drawer Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: id,
          scores: [1],
          totalScore: totalScore,
        )
      ],
      startTime: DateTime(2026),
      scheduledTime: scheduledTime ?? DateTime(2026),
      completedTime: completedTime ??
          (useDefaultCompletedTime && status == 'completed'
              ? DateTime(2026, 1, 2)
              : null),
      status: status,
    );
  }

  Widget buildHarness({
    ValueChanged<Widget>? onChangeBody,
    VoidCallback? onLogout,
    VoidCallback? onRefresh,
    ValueChanged<int>? onTabSelected,
  }) {
    return DefaultAssetBundle(
      bundle: FakeAssetBundle(),
      child: MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(
            changeBodyCallback: onChangeBody,
            onLogout: onLogout,
            onRefreshRequested: onRefresh,
            onTabSelected: onTabSelected,
          ),
          body: const Text('Body'),
        ),
      ),
    );
  }

  Future<void> openDrawer(WidgetTester tester) async {
    final scaffoldState =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('guest drawer renders account and locked navigation',
      (tester) async {
    var refreshed = false;
    await tester.pumpWidget(buildHarness(onRefresh: () => refreshed = true));

    await openDrawer(tester);

    expect(find.text('Guest Profile'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sign In / Sign Up'), findsOneWidget);
    expect(find.text('No current game'), findsOneWidget);
    expect(find.byKey(const Key('drawer-locked-preview')), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(UserAccountsDrawerHeader),
      matching: find.byType(PlayerAvatarWidget),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(LoginScreen))).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-locked-preview')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);
    final lockedLoginScreen =
        tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(lockedLoginScreen.promptMessage,
        "Sign up to schedule future rounds and sync with friends.");
    Navigator.of(tester.element(find.byType(LoginScreen))).pop();
    await tester.pumpAndSettle();

    expect(refreshed, isTrue);
  });

  testWidgets(
      'guest drawer home, login, friends, past games, and scheduled routes',
      (tester) async {
    Widget? nextBody;
    var refreshCount = 0;
    await tester.pumpWidget(buildHarness(
      onChangeBody: (widget) => nextBody = widget,
      onRefresh: () => refreshCount++,
    ));

    await openDrawer(tester);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(nextBody, isNotNull);

    await openDrawer(tester);
    await tester.tap(find.text('Sign In / Sign Up'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(LoginScreen))).pop();
    await tester.pumpAndSettle();
    expect(refreshCount, 1);

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-friends')));
    await tester.pumpAndSettle();
    expect(find.byType(PlayersScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(PlayersScreen))).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-past-games')));
    await tester.pumpAndSettle();
    expect(find.byType(PastGamesScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(PastGamesScreen))).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-scheduled-games')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);
    final scheduledLoginScreen =
        tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(scheduledLoginScreen.promptMessage,
        "Sign up to schedule future rounds and sync with friends.");
  });

  testWidgets('no active game tile opens create game and refreshes on return',
      (tester) async {
    var refreshed = false;
    await tester.pumpWidget(buildHarness(onRefresh: () => refreshed = true));
    await openDrawer(tester);

    await tester.tap(find.byKey(const Key('drawer-current-game')));
    await tester.pumpAndSettle();
    expect(find.byType(GameCreateScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(GameCreateScreen))).pop();
    await tester.pumpAndSettle();
    expect(refreshed, isTrue);
  });

  testWidgets('active game tile switches body through callback',
      (tester) async {
    final activeGame = makeGame('active_game', 'started');
    SharedPreferences.setMockInitialValues({
      'active_game': jsonEncode(activeGame.toJson()),
    });
    Widget? nextBody;

    await tester.pumpWidget(
      buildHarness(onChangeBody: (widget) => nextBody = widget),
    );
    await openDrawer(tester);

    expect(find.text('Resume Active Game'), findsOneWidget);

    await tester.tap(find.byKey(const Key('drawer-current-game')));
    await tester.pumpAndSettle();

    expect(nextBody, isA<GameInprogressScreen>());
  });

  testWidgets('logged in drawer renders account header and logout callback',
      (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p1',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);
    var loggedOut = false;

    await tester.pumpWidget(buildHarness(onLogout: () => loggedOut = true));
    await openDrawer(tester);

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Janie'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);

    final logout = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(UserAccountsDrawerHeader),
        matching: find.byType(GestureDetector),
      ),
    );
    logout.onTap!();

    expect(loggedOut, isTrue);
  });

  testWidgets(
      'logged in drawer routes to scheduled, upcoming, and recent games',
      (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p1',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);
    final recent = makeGame(
      'recent_game',
      'completed',
      completedTime: DateTime(2026, 1, 3),
      totalScore: 5,
    );
    final recentWithoutCompletedTime = makeGame(
      'recent_fallback_game',
      'completed',
      scheduledTime: DateTime(2026, 1, 2),
      useDefaultCompletedTime: false,
    );
    final upcoming = makeGame(
      'upcoming_game',
      'unstarted_game',
      scheduledTime: DateTime(2026, 1, 4),
    );
    SharedPreferences.setMockInitialValues({
      recent.id: jsonEncode(recent.toJson()),
      recentWithoutCompletedTime.id:
          jsonEncode(recentWithoutCompletedTime.toJson()),
      upcoming.id: jsonEncode(upcoming.toJson()),
    });

    await tester.pumpWidget(buildHarness());
    await openDrawer(tester);

    expect(find.textContaining(' - Score: 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('drawer-scheduled-games')));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduledGamesScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(ScheduledGamesScreen))).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    final upcomingTile = find.byKey(const Key('drawer-upcoming-upcoming_game'));
    await tester.ensureVisible(upcomingTile);
    await tester.pumpAndSettle();
    await tester.tap(upcomingTile);
    await tester.pumpAndSettle();
    expect(find.byType(GameStartScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(GameStartScreen))).pop();
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-recent-recent_game')));
    await tester.pumpAndSettle();
    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
  });

  testWidgets('guest recent game preview prompts login', (tester) async {
    final recent = makeGame('recent_game', 'completed');
    SharedPreferences.setMockInitialValues({
      recent.id: jsonEncode(recent.toJson()),
    });

    await tester.pumpWidget(buildHarness());
    await openDrawer(tester);

    await tester.tap(find.byKey(const Key('drawer-recent-recent_game')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoginScreen), findsOneWidget);
    final loginScreen = tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(loginScreen.promptMessage,
        "Login or register to view your past game details and save your history to the cloud.");
  });

  testWidgets(
      'logged in drawer invokes onTabSelected callback when tapping Friends and Past Games',
      (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p1',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);

    int? selectedTab;
    await tester.pumpWidget(buildHarness(
      onTabSelected: (index) => selectedTab = index,
    ));

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-friends')));
    await tester.pumpAndSettle();
    expect(selectedTab, equals(1));

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-past-games')));
    await tester.pumpAndSettle();
    expect(selectedTab, equals(2));
  });

  testWidgets(
      'logged in drawer changes body when DashboardScreen.onTabSelect is null but changeBodyCallback is provided',
      (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p1',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);

    Widget? nextBody;
    DashboardScreen.onTabSelect = null;

    int? selectedIndexCalled;
    await tester.pumpWidget(buildHarness(
      onChangeBody: (widget) {
        nextBody = widget;
        DashboardScreen.onTabSelect = (idx) => selectedIndexCalled = idx;
      },
    ));

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-friends')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(nextBody, isA<DashboardScreen>());
    expect(selectedIndexCalled, equals(1));

    nextBody = null;
    selectedIndexCalled = null;
    DashboardScreen.onTabSelect = null;

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-past-games')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(nextBody, isA<DashboardScreen>());
    expect(selectedIndexCalled, equals(2));
  });

  testWidgets(
      'logged in drawer calls static DashboardScreen.onTabSelect when onTabSelected is null',
      (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'p1',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);

    int? selectedIndexCalled;
    DashboardScreen.onTabSelect = (idx) => selectedIndexCalled = idx;

    await tester.pumpWidget(buildHarness(
      onTabSelected: null,
    ));

    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-friends')));
    await tester.pumpAndSettle();
    expect(selectedIndexCalled, equals(1));

    selectedIndexCalled = null;
    await openDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer-past-games')));
    await tester.pumpAndSettle();
    expect(selectedIndexCalled, equals(2));
  });
}

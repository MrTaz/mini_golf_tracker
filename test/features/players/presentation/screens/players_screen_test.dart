import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';
import 'package:mini_golf_tracker/features/players/presentation/screens/players_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [
      Player(
          id: 'p1',
          playerName: 'Ava Guest',
          nickname: 'Ava',
          ownerId: 'guest',
          totalScore: 0),
      Player(
          id: 'p2',
          playerName: 'Ben Guest',
          nickname: 'Ben',
          ownerId: 'guest',
          totalScore: 0),
      Player(
          id: 'p3',
          playerName: 'Charlie Guest',
          nickname: 'Charlie',
          ownerId: 'guest',
          totalScore: 0),
    ];
  });

  tearDown(() {
    Player.players = [];
    UserProvider().resetForTesting();
  });

  testWidgets('PlayersScreen preserves selected players across rebuilds',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 1);

    // Trigger a rebuild by calling setState (simulated by tapping FAB and closing it)
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    expect(find.text('New Player'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    final stateAfter =
        tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(stateAfter.selectedPlayers.length, 1);
  });

  testWidgets('PlayersScreen injects guest scorekeeper first', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.players.first.id, 'guest');
    expect(state.players.first.playerName, 'Guest');
    expect(state.players.first.nickname, 'Guest Scorekeeper');
  });

  testWidgets('PlayersScreen injects logged-in user first', (tester) async {
    final owner = Player(
      id: 'owner-1',
      playerName: 'Owner Player',
      nickname: 'Owner',
      ownerId: 'owner-1',
      totalScore: 0,
    );
    UserProvider().loggedInUser = owner;

    await tester
        .pumpWidget(const MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.players.first.id, 'owner-1');
    expect(
        state.players.where((player) => player.id == 'owner-1'), hasLength(1));
  });

  testWidgets('PlayersScreen receives currentlySelectedPlayers as List<Player>',
      (tester) async {
    final List<Player> preSelected = [Player.players[0]];

    await tester.pumpWidget(MaterialApp(
        home: PlayersScreen(
            creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 1);
    expect(state.selectedPlayers.first.id, 'p1');
  });

  testWidgets(
      'PlayersScreen receives currentlySelectedPlayers as List<PlayerGameInfo>',
      (tester) async {
    final List<PlayerGameInfo> preSelected = [
      PlayerGameInfo(playerId: 'p2', gameId: 'g1', scores: [])
    ];

    await tester.pumpWidget(MaterialApp(
        home: PlayersScreen(
            creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 1);
    expect(state.selectedPlayers.first.id, 'p2');
  });

  testWidgets('PlayersScreen clears all selected players', (tester) async {
    final List<Player> preSelected = [Player.players[0], Player.players[1]];

    await tester.pumpWidget(MaterialApp(
        home: PlayersScreen(
            creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 2);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(state.selectedPlayers.length, 0);
  });

  testWidgets(
      'PlayersScreen handles null and unrecognized types in currentlySelectedPlayers',
      (tester) async {
    final List<dynamic> preSelected = [
      null,
      Player.players[0],
      'some unexpected string',
      PlayerGameInfo(playerId: 'p2', gameId: 'g1', scores: [])
    ];

    await tester.pumpWidget(MaterialApp(
        home: PlayersScreen(
            creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 2);
    final selectedIds = state.selectedPlayers.map((p) => p.id).toList();
    expect(selectedIds.contains('p1'), isTrue);
    expect(selectedIds.contains('p2'), isTrue);
  });

  testWidgets('PlayersScreen shows offline banner when _isOffline is true',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));

    // Manually trigger offline state
    state.setOfflineForTesting(true);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.textContaining('Offline mode: showing cached friends'),
        findsOneWidget);
  });

  testWidgets(
      'PlayersScreen shows offline empty-state message when offline and no players',
      (tester) async {
    // Use a logged-in user with no friends so the players list stays empty.
    final owner = Player(
      id: 'owner-empty',
      playerName: 'Owner',
      nickname: 'Owner',
      ownerId: 'owner-empty',
      totalScore: 0,
    );
    UserProvider().loggedInUser = owner;
    Player.players = []; // No players so the offline empty state triggers.

    await tester
        .pumpWidget(const MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));

    // Manually set both offline + empty state
    state.setOfflineForTesting(true);
    state.clearPlayersForTesting();
    await tester.pumpAndSettle();

    expect(
        find.textContaining(
            "We couldn't load your friends. Please check your internet connection"),
        findsOneWidget);
  });

  testWidgets(
      'PlayersScreen shows Friends appbar for guest user (non-creating)',
      (tester) async {
    // loggedInUser is null (guest), creatingGame is false → appbar title: 'Friends'
    await tester.pumpWidget(
        const MaterialApp(home: PlayersScreen(creatingGame: false)));
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsOneWidget);
  });
}

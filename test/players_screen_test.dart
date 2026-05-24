import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [
      Player(id: 'p1', playerName: 'Ava Guest', nickname: 'Ava', ownerId: 'guest', totalScore: 0),
      Player(id: 'p2', playerName: 'Ben Guest', nickname: 'Ben', ownerId: 'guest', totalScore: 0),
      Player(id: 'p3', playerName: 'Charlie Guest', nickname: 'Charlie', ownerId: 'guest', totalScore: 0),
    ];
  });

  tearDown(() {
    Player.players = [];
    UserProvider().resetForTesting();
  });

  testWidgets('PlayersScreen preserves selected players across rebuilds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlayersScreen(creatingGame: true)));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 1);

    // Trigger a rebuild by calling setState (simulated by tapping FAB and closing it)
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    final stateAfter = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(stateAfter.selectedPlayers.length, 1);
  });

  testWidgets('PlayersScreen receives currentlySelectedPlayers as List<Player>', (tester) async {
    final List<Player> preSelected = [Player.players[0]];

    await tester.pumpWidget(MaterialApp(home: PlayersScreen(creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 1);
    expect(state.selectedPlayers.first.id, 'p1');
  });

  testWidgets('PlayersScreen receives currentlySelectedPlayers as List<PlayerGameInfo>', (tester) async {
    final List<PlayerGameInfo> preSelected = [PlayerGameInfo(playerId: 'p2', gameId: 'g1', scores: [])];

    await tester.pumpWidget(MaterialApp(home: PlayersScreen(creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 1);
    expect(state.selectedPlayers.first.id, 'p2');
  });

  testWidgets('PlayersScreen clears all selected players', (tester) async {
    final List<Player> preSelected = [Player.players[0], Player.players[1]];

    await tester.pumpWidget(MaterialApp(home: PlayersScreen(creatingGame: true, currentlySelectedPlayers: preSelected)));
    await tester.pumpAndSettle();

    final state = tester.state<PlayersScreenState>(find.byType(PlayersScreen));
    expect(state.selectedPlayers.length, 2);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(state.selectedPlayers.length, 0);
  });
}

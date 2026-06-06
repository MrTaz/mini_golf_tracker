// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_create_screen.dart';
import 'package:mini_golf_tracker/features/players/presentation/screens/players_screen.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    Player.players = [
      Player(
        id: 'p1',
        playerName: 'Ava Guest',
        nickname: 'Ava',
        ownerId: 'guest',
        totalScore: 0,
      ),
      Player(
        id: 'p2',
        playerName: 'Ben Guest',
        nickname: 'Ben',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
  });

  patrolTest('Player selection flow: select and clear players', ($) async {
    await $.pumpWidgetAndSettle(
      const MaterialApp(
        home: GameCreateScreen(),
      ),
    );
    await $.pump(const Duration(milliseconds: 350));

    // Initial state: 0 players
    expect($('0 players selected'), findsOneWidget);

    // Open Player Selection screen
    await $('Players').tap();
    await $.pump(const Duration(milliseconds: 350));

    expect($(PlayersScreen), findsOneWidget);

    // Select Ava by tapping the Switch
    await $(Switch).first.tap();
    await $.pumpAndSettle();

    // Confirm selection (Add selected players to game.)
    await $('Add selected players to game.').tap();
    await $.pump(const Duration(milliseconds: 350));

    // Should be back on Create Game
    expect($(GameCreateScreen), findsOneWidget);
    expect($('1 player selected'), findsOneWidget);

    // Open Player Selection screen again
    await $('Players').tap();
    await $.pump(const Duration(milliseconds: 350));

    expect($(PlayersScreen), findsOneWidget);

    // Clear selections using AppBar action "Clear All"
    await $('Clear All').tap();
    await $.pumpAndSettle();

    // Confirm selection (Add selected players to game.)
    await $('Add selected players to game.').tap();
    await $.pump(const Duration(milliseconds: 350));

    // Verifies the Create Game screen correctly updates to show 0 players selected.
    expect($(GameCreateScreen), findsOneWidget);
    expect($('0 players selected'), findsOneWidget);
  });
}

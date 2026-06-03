// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/main.dart' as app;
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  patrolTest('Pause reminder coach mark appears on app resume and is dismissible', ($) async {
    app.MainScaffold.skipPrecacheForTesting = true;

    final testGame = Game(
      id: 'test_game_id',
      name: 'Test Game',
      course: Course(id: 'c1', name: 'Test Course', numberOfHoles: 2, parStrokes: {1: 3, 2: 3}),
      players: [
        PlayerGameInfo(playerId: 'p1', gameId: 'test_game_id', scores: []),
      ],
      scheduledTime: DateTime.now(),
      startTime: DateTime.now(),
      status: 'started',
    );
    
    Player.players = [
      Player(id: 'p1', playerName: 'P1', nickname: 'P1', ownerId: 'guest', totalScore: 0, email: 'p1@example.com'),
    ];

    SharedPreferences.setMockInitialValues({
      'test_game_id': jsonEncode(testGame.toJson()),
      'guest_players': jsonEncode(Player.players.map((p) => p.toJson()).toList()),
    });

    await $.pumpWidgetAndSettle(const app.MyApp());

    expect($(GameInprogressScreen), findsOneWidget);

    expect($("Need a break? You can safely pause your game here!"), findsNothing);

    // Simulate app resume
    $.tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await $.pumpAndSettle();

    expect($("Need a break? You can safely pause your game here!"), findsOneWidget);

    // Tap on the coach mark to dismiss it
    await $("Need a break? You can safely pause your game here!").tap();
    await $.pumpAndSettle();

    expect($("Need a break? You can safely pause your game here!"), findsNothing);
  });
}

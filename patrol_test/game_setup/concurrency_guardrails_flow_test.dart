// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/game_create_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  setUp(() async {
    final fakeFirestore = FakeFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(mockAuth);
  });

  patrolTest('Concurrency Guardrails: active game warning dialog interrupts flow', ($) async {
    // Inject an active game
    final activeGame = Game(
      id: 'active_game_1',
      name: 'Active Integration Game',
      course: Course(
        id: 'course_1',
        name: 'Test Course',
        numberOfHoles: 18,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'test_player',
          gameId: 'active_game_1',
          scores: [],
        )
      ],
      scheduledTime: DateTime.now(),
      status: 'started',
    );
    SharedPreferences.setMockInitialValues({'active_game_1': jsonEncode(activeGame.toJson())});

    // Pump the GameCreateScreen directly under a MaterialApp to strictly simulate E2E UI actions.
    await $.pumpWidgetAndSettle(
      const MaterialApp(
        home: GameCreateScreen(),
      ),
    );

    // Set course and players for testing in GameCreateScreenState
    final gameCreateState =
        $.tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    gameCreateState.setSelectedCourseForTesting(Course(
      id: 'course_1',
      name: 'Test Course',
      numberOfHoles: 18,
      parStrokes: {1: 3},
    ));
    gameCreateState.setSelectedPlayersForTesting([
      Player(
        id: 'test_player',
        playerName: 'Test Player',
        nickname: 'Tester',
        ownerId: 'guest',
        totalScore: 0,
      ),
      Player(
        id: 'player_2',
        playerName: 'Player Two',
        nickname: 'Two',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ]);
    await $.pump();

    // Enter game name strictly via UI TextFormField
    await $(TextFormField).at(0).enterText('New Game Attempt');
    await $.pump();
    
    // Tap the 'Create Game' button to trigger the game startup flow
    final createBtn = find.widgetWithText(ElevatedButton, 'Create Game');
    // Ensure button is visible
    await $.tester.ensureVisible(createBtn);
    await $(createBtn).tap();
    await $.pump(const Duration(milliseconds: 500));
    await $.pumpAndSettle();

    // The "You already have a game in progress" warning dialog should appear
    expect($('Warning'), findsOneWidget);
    expect($('Cancel'), findsOneWidget);
    expect($('Continue'), findsOneWidget);

    // Cancel flow via dialog UI Cancel button tap
    await $('Cancel').tap();
    await $.pump(const Duration(milliseconds: 500));
    await $.pumpAndSettle();

    // Should still be on Create Game Screen and dialog dismissed
    expect($('New Game Attempt'), findsOneWidget);
    expect($(GameCreateScreen), findsOneWidget);

    // Try again and continue
    await $(createBtn).tap();
    await $.pump(const Duration(milliseconds: 500));
    await $.pumpAndSettle();
    
    await $('Continue').tap();
    await $.pump(const Duration(milliseconds: 500));
    await $.pumpAndSettle();

    // Now it should successfully proceed to GameInprogressScreen via route transition
    expect($(GameInprogressScreen), findsOneWidget);
  });
}

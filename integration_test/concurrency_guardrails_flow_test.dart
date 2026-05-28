// ignore_for_file: avoid_print, use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final fakeFirestore = FakeFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(mockAuth);
  });

  testWidgets('Concurrency Guardrails: active game warning dialog interrupts flow', (tester) async {
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
    await tester.pumpWidget(
      const MaterialApp(
        home: GameCreateScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Set course and players for testing in GameCreateScreenState
    final gameCreateState =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
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
    await tester.pump();

    // Enter game name strictly via UI TextFormField
    await tester.enterText(find.byType(TextFormField).first, 'New Game Attempt');
    await tester.pump();
    
    // Tap the 'Create Game' button to trigger the game startup flow
    final createBtn = find.widgetWithText(ElevatedButton, 'Create Game');
    // Ensure button is visible
    await tester.ensureVisible(createBtn);
    await tester.tap(createBtn);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // The "You already have a game in progress" warning dialog should appear
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Cancel flow via dialog UI Cancel button tap
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Should still be on Create Game Screen and dialog dismissed
    expect(find.text('New Game Attempt'), findsOneWidget);
    expect(find.byType(GameCreateScreen), findsOneWidget);

    // Try again and continue
    await tester.tap(createBtn);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Now it should successfully proceed to GameInprogressScreen via route transition
    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });
}

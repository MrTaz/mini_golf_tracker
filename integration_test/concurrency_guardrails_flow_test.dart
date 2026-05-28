import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/main.dart' as app;
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});
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

    app.main();
    await tester.pumpAndSettle();

    // In a fresh start with an active game, app auto-resumes to GameInprogressScreen.
    // We want to test the Create Game flow, so we pop back to ActivityHub.
    expect(find.text('End Game'), findsOneWidget); // Confirm we are in GameInprogress
    await tester.tap(find.byIcon(Icons.arrow_back)); // Usually a back button exists to go to dashboard
    await tester.pumpAndSettle();

    // From ActivityHub, tap FAB to create game
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Enter game name
    await tester.enterText(find.byType(TextFormField).first, 'New Game Attempt');
    
    // Tap to start
    final createBtn = find.widgetWithText(ElevatedButton, 'Create Game');
    // Ensure button is visible
    await tester.ensureVisible(createBtn);
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    // The warning dialog should appear
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Cancel flow
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Should still be on Create Game Screen
    expect(find.text('New Game Attempt'), findsOneWidget);

    // Try again and continue
    await tester.tap(createBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Now it should proceed to GameInprogressScreen
    expect(find.text('End Game'), findsOneWidget);
  });
}

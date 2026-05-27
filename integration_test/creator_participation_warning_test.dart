import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Player creator;
  late Game unstartedGame;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();

    // Creator is "Jane Doe" but is intentionally NOT in the game's player list.
    creator = Player(
      id: 'creator-id',
      playerName: 'Jane Doe',
      nickname: 'Jane',
      ownerId: 'creator-id',
      totalScore: 0,
    );

    // Seed Player.players with two guest players (no creator).
    Player.players = [
      Player(
        id: 'guest-1',
        playerName: 'Guest 1',
        nickname: 'Guest1',
        ownerId: 'guest',
        totalScore: 0,
      ),
      Player(
        id: 'guest-2',
        playerName: 'Guest 2',
        nickname: 'Guest2',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ];

    // Set the creator as the logged-in user.
    UserProvider().loggedInUser = creator;

    // Build an unstarted game whose player list does NOT include the creator.
    unstartedGame = Game(
      id: 'test-game-id',
      name: 'Creator Warning Test Game',
      course: Course(
        id: 'test-course-id',
        name: 'Test Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'guest-1',
          gameId: 'test-game-id',
          scores: [],
        ),
        PlayerGameInfo(
          playerId: 'guest-2',
          gameId: 'test-game-id',
          scores: [],
        ),
      ],
      scheduledTime: DateTime(2026),
      status: 'unstarted_game',
    );
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
  });

  testWidgets(
    'Creator participation warning: Cancel dismisses dialog, Start Anyway navigates to GameInprogressScreen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameStartScreen(unstartedGame: unstartedGame),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Tap "Start the game!" FAB.
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Start the game!'));
      await tester.pumpAndSettle();

      // Step 2: Verify the warning dialog appears.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('You are not playing!'), findsOneWidget);

      // Step 3: Tap "Cancel" and verify dialog dismisses.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(GameStartScreen), findsOneWidget);

      // Step 4: Tap "Start the game!" again to re-trigger the dialog.
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Start the game!'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('You are not playing!'), findsOneWidget);

      // Step 5: Tap "Start Anyway" and verify navigation to GameInprogressScreen.
      await tester.tap(find.byKey(const Key('btnStartAnyway')));
      await tester.pumpAndSettle();

      expect(find.byType(GameInprogressScreen), findsOneWidget);
    },
  );
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    Player.players = [
      Player(
        id: 'p1',
        playerName: 'Integration Player',
        nickname: 'Player',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ];
  });

  Game makeGame({String status = 'started'}) {
    return Game(
      id: 'phase_1_19_game',
      name: 'Phase 1.19 Game',
      course: Course(
        id: 'phase_1_19_course',
        name: 'Phase 1.19 Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'phase_1_19_game',
          scores: status == 'completed' ? [2] : [],
          totalScore: status == 'completed' ? 2 : 0,
        ),
      ],
      scheduledTime: DateTime(2026),
      startTime: DateTime(2026),
      completedTime: status == 'completed' ? DateTime(2026, 1, 1, 12) : null,
      status: status,
    );
  }

  testWidgets('active game plus button increments zero score to one',
      (tester) async {
    final game = makeGame();

    await tester.pumpWidget(MaterialApp(
      home: GameInprogressScreen(currentGame: game),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(game.players.single.scores, [1]);
  });

  testWidgets('past game details exposes shared drawer for guests',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PastGameDetailsScreen(passedGame: makeGame(status: 'completed')),
    ));
    await tester.pumpAndSettle();

    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Guest Profile'), findsOneWidget);
    expect(find.text('No current game'), findsOneWidget);
  });
}

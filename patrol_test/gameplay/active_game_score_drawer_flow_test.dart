// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
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

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
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

  patrolTest('Active game score increments and past game details exposes drawer', ($) async {
    // 1. Test: active game plus button increments zero score to one
    final game = makeGame();
    await $.pumpWidgetAndSettle(MaterialApp(
      home: GameInprogressScreen(currentGame: game),
    ));

    await $(Icons.add).first.tap();
    await $.pumpAndSettle();

    expect(game.players.single.scores, [1]);

    // Clear SharedPreferences before the second step to prevent the active game
    // saved in step 1 from showing up as an active game in the drawer.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 2. Test: past game details exposes shared drawer for guests
    await $.pumpWidgetAndSettle(MaterialApp(
      home: PastGameDetailsScreen(passedGame: makeGame(status: 'completed')),
    ));

    final scaffoldState = $.tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await $.pump();
    await $.pump(const Duration(milliseconds: 500));

    expect($('Guest Profile'), findsOneWidget);
    expect($('No current game'), findsOneWidget);
  });
}

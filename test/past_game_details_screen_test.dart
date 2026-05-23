import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/app_drawer_widget.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    UserProvider().resetForTesting();
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    SharedPreferences.setMockInitialValues({});
    Player.players = [
      Player(
        id: 'p1',
        playerName: 'Past Player',
        nickname: 'Past',
        ownerId: 'guest',
        totalScore: 0,
      )
    ];
  });

  Game makePastGame() {
    return Game(
      id: 'past_game',
      name: 'Past Game',
      course: Course(
        id: 'c1',
        name: 'Past Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'past_game',
          scores: [2],
          totalScore: 2,
        )
      ],
      scheduledTime: DateTime(2026),
      startTime: DateTime(2026),
      completedTime: DateTime(2026, 1, 1, 12),
      status: 'completed',
    );
  }

  testWidgets('past game details exposes the shared app drawer',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PastGameDetailsScreen(passedGame: makePastGame())),
    );
    await tester.pumpAndSettle();

    final scaffoldState =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.byType(AppDrawer), findsOneWidget);
    expect(find.text('Guest Profile'), findsOneWidget);
    expect(find.text('No current game'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [_guestPlayer('p1', 'Ava'), _guestPlayer('p2', 'Ben')];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    Player.players = [];
  });

  testWidgets('guest scheduling is redirected to LoginScreen', (tester) async {
    final game = _guestGame();

    await tester.pumpWidget(
      MaterialApp(home: GameStartScreen(unstartedGame: game)),
    );

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    // Pump to let the FlutterLogin intro animation timers complete
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('auth user can schedule a valid game', (tester) async {
    final game = _guestGame();
    final player = Player(
      id: 'auth-uid',
      playerName: 'Jane Doe',
      nickname: 'Janie',
      ownerId: 'auth-uid',
      totalScore: 0,
      email: 'jane@example.com',
    );
    await UserProvider().login(player);

    await tester.pumpWidget(
      MaterialApp(home: GameStartScreen(unstartedGame: game)),
    );

    await tester.tap(find.text('Schedule game'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(game.id), isNotNull);
  });

  testWidgets('guest can start a valid game without a database save',
      (tester) async {
    final game = _guestGame();

    await tester.pumpWidget(
      MaterialApp(home: GameStartScreen(unstartedGame: game)),
    );

    await tester.tap(find.text('Start the game!'));
    await tester.pumpAndSettle();

    expect(find.byType(GameInprogressScreen), findsOneWidget);
  });

  testWidgets('guest in-progress game updates locally on completion',
      (tester) async {
    final game = _guestGame(
      scores: const [
        [2],
        [3],
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: GameInprogressScreen(currentGame: game)),
    );

    await tester.tap(find.text('Complete Game'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(game.id), isNotNull);
    expect(game.status, 'completed');
  });
}

Player _guestPlayer(String id, String nickname) {
  return Player(
    id: id,
    playerName: '$nickname Guest',
    nickname: nickname,
    ownerId: 'guest',
    totalScore: 0,
  );
}

Game _guestGame({List<List<int>>? scores}) {
  return Game(
    id: 'guest-game',
    name: 'Guest Game',
    course: Course(
      id: 'course-1',
      name: 'Guest Course',
      numberOfHoles: 1,
      parStrokes: {1: 3},
    ),
    players: [
      PlayerGameInfo(
        playerId: 'p1',
        gameId: 'guest-game',
        scores: scores?[0] ?? [],
      ),
      PlayerGameInfo(
        playerId: 'p2',
        gameId: 'guest-game',
        scores: scores?[1] ?? [],
      ),
    ],
    scheduledTime: DateTime(2026, 5, 17, 10),
  );
}

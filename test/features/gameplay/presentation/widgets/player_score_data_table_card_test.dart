import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/courses/data/models/course.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';
import 'package:mini_golf_tracker/features/gameplay/presentation/widgets/player_score_data_table_card.dart';

void main() {
  testWidgets('PlayerScoreDataTable renders empty state',
      (WidgetTester tester) async {
    final game = Game(
      id: 'g1',
      name: 'Test Game',
      course: Course(
          id: 'c1', name: 'Test Course', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [],
      scheduledTime: DateTime.now(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerScoreDataTable(
          clickedPlayers: [],
          clickedPlayerScores: [],
          game: game,
        ),
      ),
    ));

    expect(find.text('No players selected.'), findsOneWidget);
  });

  testWidgets('PlayerScoreDataTable renders scores correctly',
      (WidgetTester tester) async {
    final course = Course(
        id: 'c1',
        name: 'Test Course',
        numberOfHoles: 2,
        parStrokes: {1: 3, 2: 4});
    final game = Game(
      id: 'g1',
      name: 'Test Game',
      course: course,
      players: [],
      scheduledTime: DateTime.now(),
    );

    final player1 = Player(
        id: 'p1',
        playerName: 'Alice',
        nickname: 'A',
        ownerId: 'p1',
        totalScore: 0);
    final player2 = Player(
        id: 'p2',
        playerName: 'Bob',
        nickname: 'B',
        ownerId: 'p2',
        totalScore: 0);

    final score1 = PlayerGameInfo(
      playerId: 'p1',
      gameId: 'g1',
      scores: [3, 5], // Par on hole 1, +1 on hole 2
      playOrderPosition: 0,
      place: '1st',
      totalScore: 8,
      strokes: 8,
      scoreTimestamps: [],
    );
    final score2 = PlayerGameInfo(
      playerId: 'p2',
      gameId: 'g1',
      scores: [2], // -1 on hole 1, missing hole 2
      playOrderPosition: 1,
      place: '2nd',
      totalScore: 2,
      strokes: 2,
      scoreTimestamps: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerScoreDataTable(
          clickedPlayers: [player1, player2],
          clickedPlayerScores: [score1, score2],
          game: game,
        ),
      ),
    ));

    // Verify headers
    expect(find.text('Hole'), findsOneWidget);
    expect(find.text('A\n1st'), findsOneWidget);
    expect(find.text('B\n2nd'), findsOneWidget);

    // Verify row 1
    expect(find.text('1 (3)'), findsOneWidget);
    expect(find.text('3 '), findsOneWidget); // Alice (par)
    expect(find.text('2 (-1)'), findsOneWidget); // Bob (-1)

    // Verify row 2
    expect(find.text('2 (4)'), findsOneWidget);
    expect(find.text('5 (+1)'), findsOneWidget); // Alice (+1)

    // Verify totals
    expect(find.text('Total'), findsWidgets);
    expect(find.text('8'), findsWidgets); // Alice total
    expect(find.text('2'), findsWidgets); // Bob total
  });
}

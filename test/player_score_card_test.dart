import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/player_score_card.dart';

void main() {
  testWidgets('PlayerScoreCard renders correctly and handles selection', (WidgetTester tester) async {
    final scores = [
      PlayerGameInfo(
        playerId: 'p1',
        gameId: 'g1',
        scores: [3, 2],
        playOrderPosition: 0,
        place: '1',
        totalScore: 5,
        strokes: 5,
        scoreTimestamps: [],
      ),
      PlayerGameInfo(
        playerId: 'p2',
        gameId: 'g1',
        scores: [4, 5],
        playOrderPosition: 1,
        place: '2',
        totalScore: 9,
        strokes: 9,
        scoreTimestamps: [],
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerScoreCard(sortedPlayerScores: scores),
      ),
    ));

    expect(find.text('Player p1'), findsOneWidget);
    expect(find.text('Player p2'), findsOneWidget);
    
    // Scores are not visible yet
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);

    // Tap on player p1
    await tester.tap(find.text('Player p1'));
    await tester.pumpAndSettle();

    // Scores for p1 should be visible
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    
    // Tap again to unselect
    await tester.tap(find.text('Player p1'));
    await tester.pumpAndSettle();
    
    expect(find.text('3'), findsNothing);
  });
}

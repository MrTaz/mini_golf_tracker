import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';

import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/scheduled_games_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows loading then empty state when no games exist', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('No scheduled games'), findsOneWidget);
  });

  testWidgets('renders list of scheduled games', (tester) async {
    final game = Game(
      id: 'g1',
      name: 'Upcoming Test Game',
      course: Course(
        id: 'c1',
        name: 'Test Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'g1',
          scores: [0],
        )
      ],
      scheduledTime: DateTime(2026, 1, 1, 10, 0),
      status: 'unstarted_game',
    );

    SharedPreferences.setMockInitialValues({
      'g1': jsonEncode(game.toJson()),
    });

    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Test Game'), findsOneWidget);
    expect(find.textContaining('Test Course'), findsOneWidget);
  });

  testWidgets('tapping a game navigates to GameStartScreen and reloads games on return', (tester) async {
    final game = Game(
      id: 'g1',
      name: 'Upcoming Test Game',
      course: Course(
        id: 'c1',
        name: 'Test Course',
        numberOfHoles: 1,
        parStrokes: {1: 3},
      ),
      players: [
        PlayerGameInfo(
          playerId: 'p1',
          gameId: 'g1',
          scores: [1], // Use 1 to prevent DropdownMenuItem value error
        )
      ],
      scheduledTime: DateTime(2026, 1, 1, 10, 0),
      status: 'unstarted_game',
    );

    SharedPreferences.setMockInitialValues({
      'g1': jsonEncode(game.toJson()),
    });

    await tester.pumpWidget(const MaterialApp(home: ScheduledGamesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upcoming Test Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameStartScreen), findsOneWidget);

    // Now tap back to trigger the pop and reload
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduledGamesScreen), findsOneWidget);
  });
}

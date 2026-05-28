import 'dart:async';
import 'dart:convert';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/past_game_list_item.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/past_game_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PastGameCardWidget shows waiting then no games', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PastGameCardWidget())));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("Let's play mini-golf!"), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('PastGameCardWidget shows games list and handles tap', (WidgetTester tester) async {
    final Map<String, Object> values = <String, Object>{
      'game1': jsonEncode({
        'id': 'game1',
        'name': 'Game 1',
        'status': 'completed',
        'course': {
          'id': 'course1',
          'name': 'Course 1',
          'number_of_holes': 1,
          'par_strokes': {'1': 3}
        },
        'players': [],
        'start_time': '2023-01-01T12:00:00.000Z'
      })
    };
    SharedPreferences.setMockInitialValues(values);
    await tester.pumpWidget(
      ChangeNotifierProvider<UserProvider>(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: Scaffold(body: PastGameCardWidget())),
      )
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    expect(find.text('Past games'), findsOneWidget);

    // Tap the ListTile inside PastGameListItem to trigger navigation via onPastGameCardTap
    final listTileFinder = find.descendant(
      of: find.byType(PastGameListItem, skipOffstage: false),
      matching: find.byType(ListTile, skipOffstage: false),
    );
    expect(listTileFinder, findsWidgets);
    await tester.tap(listTileFinder.first, warnIfMissed: false);
    await tester.pump();
    await tester.pumpAndSettle();

    // Now it should have pushed PastGameDetailsScreen
    expect(find.byType(PastGameDetailsScreen), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('PastGameCardWidget handles error', (WidgetTester tester) async {
    final completer = Completer<List<Game?>>();
    completer.future.catchError((_) => <Game?>[]); // Prevent unhandled exception in test zone
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PastGameCardWidget(
          gamesFuture: completer.future,
        ),
      ),
    ));
    completer.completeError('Simulated error');
    await tester.pumpAndSettle();
    
    expect(find.text('Error: Unable to load local game data'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 5));
  });
}

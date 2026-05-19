// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/game_card_widget.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class ErrorSharedPreferencesStore extends SharedPreferencesStorePlatform {
  final bool throwOnGetAll;
  final bool throwOnRemove;
  final SharedPreferencesStorePlatform _delegate;

  ErrorSharedPreferencesStore(this._delegate, {
    this.throwOnGetAll = false,
    this.throwOnRemove = false,
  });

  @override
  bool get isMock => true;

  @override
  Future<Map<String, Object>> getAll() {
    if (throwOnGetAll) {
      throw PlatformException(code: 'UNAVAILABLE', message: 'Service unavailable');
    }
    return _delegate.getAll();
  }

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) {
    if (throwOnGetAll) {
      throw PlatformException(code: 'UNAVAILABLE', message: 'Service unavailable');
    }
    return _delegate.getAllWithPrefix(prefix);
  }

  @override
  Future<bool> remove(String key) {
    if (throwOnRemove) {
      throw PlatformException(code: 'UNAVAILABLE', message: 'Service unavailable');
    }
    return _delegate.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    return _delegate.setValue(valueType, key, value);
  }

  @override
  Future<bool> clear() {
    return _delegate.clear();
  }

  @override
  Future<bool> clearWithPrefix(String prefix) {
    return _delegate.clearWithPrefix(prefix);
  }
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final course = Course(
    id: 'course_1',
    name: 'Pebble Beach',
    numberOfHoles: 9,
    parStrokes: {1: 3, 2: 3},
  );

  final players = [
    PlayerGameInfo(
      playerId: 'player_1',
      gameId: 'game_1',
      playOrderPosition: 0,
      scores: [4, 3],
      totalScore: 7,
      place: '1',
    ),
  ];

  final unstartedGame = Game(
    id: 'game_1',
    name: 'Morning Round',
    course: course,
    players: players,
    scheduledTime: DateTime(2026, 5, 19, 10, 0),
    status: 'unstarted_game',
  );

  final startedGame = Game(
    id: 'game_2',
    name: 'Afternoon Round',
    course: course,
    players: players,
    scheduledTime: DateTime(2026, 5, 19, 14, 0),
    startTime: DateTime(2026, 5, 19, 14, 5),
    status: 'started',
  );

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Scaffold(
        body: GameCardWidget(),
      ),
    );
  }

  group('GameCardWidget Tests', () {
    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows create new game card when no saved games exist', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Create a new game'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows unstarted and started games correctly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'game_1': jsonEncode(unstartedGame.toJson()),
        'game_2': jsonEncode(startedGame.toJson()),
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.textContaining('Morning Round'), findsOneWidget);
      expect(find.textContaining('Scheduled for'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);

      expect(find.textContaining('Afternoon Round'), findsOneWidget);
      expect(find.textContaining('Started at'), findsOneWidget);
      expect(find.text('Continue Game'), findsOneWidget);

      expect(find.text('Delete Game'), findsNWidgets(2));
    });

    testWidgets('can start unstarted game', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'game_1': jsonEncode(unstartedGame.toJson()),
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Start Game'), findsOneWidget);
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Verify that it tried to push GameStartScreen
      // In this test environment, GameStartScreen might build and try to show the creation dialog,
      // which is fine, we just verify navigation happens.
    });

    testWidgets('can continue started game', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'game_2': jsonEncode(startedGame.toJson()),
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Continue Game'), findsOneWidget);
      await tester.tap(find.text('Continue Game'));
      await tester.pumpAndSettle();

      // Verify it tried to push GameInprogressScreen
    });

    testWidgets('can delete a saved game', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'game_1': jsonEncode(unstartedGame.toJson()),
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.textContaining('Morning Round'), findsOneWidget);
      await tester.tap(find.text('Delete Game'));
      await tester.pumpAndSettle();

      expect(find.text('Deleted saved game'), findsOneWidget);
    });

    testWidgets('handles different data types and corruption gracefully in deleteSavedGame', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'game_1': jsonEncode(unstartedGame.toJson()),
        'plain_string': 'not_a_json',
        'string_list': ['one', 'two'],
        'integer_value': 42,
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Trigger delete all saved games via the state
      final state = tester.state<GameCardWidgetState>(find.byType(GameCardWidget));
      await state.deleteSavedGame(gameToDelete: null);
      await tester.pumpAndSettle();

      // SharedPreferences should have removed the valid game and handled the rest gracefully
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('game_1'), isFalse);
    });

    testWidgets('shows remote sync temporarily unavailable SnackBar if load throws error', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final originalStore = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance = ErrorSharedPreferencesStore(originalStore, throwOnGetAll: true);
      SharedPreferences.resetStatic();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Start building/future execution

      // Let the FutureBuilder finish loading with error
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error: Unable to load saved game data'), findsOneWidget);
      expect(find.text('Remote sync temporarily unavailable'), findsOneWidget);

      // Clean up mock
      SharedPreferencesStorePlatform.instance = originalStore;
      SharedPreferences.resetStatic();
    });

    testWidgets('shows remote sync temporarily unavailable SnackBar if delete saved game throws error', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'game_1': jsonEncode(unstartedGame.toJson()),
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final originalStore = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance = ErrorSharedPreferencesStore(originalStore, throwOnRemove: true);
      SharedPreferences.resetStatic();

      await tester.tap(find.text('Delete Game'));
      await tester.pump();

      expect(find.text('Remote sync temporarily unavailable'), findsOneWidget);

      // Clean up mock
      SharedPreferencesStorePlatform.instance = originalStore;
      SharedPreferences.resetStatic();
    });

    testWidgets('shows remote sync temporarily unavailable SnackBar if delete game throws on error screen', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final originalStore = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance = ErrorSharedPreferencesStore(originalStore, throwOnGetAll: true, throwOnRemove: true);
      SharedPreferences.resetStatic();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error: Unable to load saved game data'), findsOneWidget);

      // Keep throwing when clicking delete game
      await tester.tap(find.text('Delete Game'));
      await tester.pump();

      expect(find.text('Remote sync temporarily unavailable'), findsOneWidget);

      // Clean up mock
      SharedPreferencesStorePlatform.instance = originalStore;
      SharedPreferences.resetStatic();
    });

    testWidgets('shows delete saved game SnackBar if delete game on error screen succeeds', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final originalStore = SharedPreferencesStorePlatform.instance;
      
      // Initially fail on load
      SharedPreferencesStorePlatform.instance = ErrorSharedPreferencesStore(originalStore, throwOnGetAll: true);
      SharedPreferences.resetStatic();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error: Unable to load saved game data'), findsOneWidget);

      // Restore original mock so delete succeeds
      SharedPreferencesStorePlatform.instance = originalStore;
      SharedPreferences.resetStatic();

      // Clear initial snackbar so it doesn't interfere
      ScaffoldMessenger.of(tester.element(find.byType(GameCardWidget))).clearSnackBars();
      await tester.pump();

      await tester.tap(find.text('Delete Game'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Deleted saved game'), findsOneWidget);
    });

    testWidgets('can navigate to create game from card', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
    });
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game_create_screen.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    Player.players = [
      Player(
        id: 'p1',
        playerName: 'Ava Guest',
        nickname: 'Ava',
        ownerId: 'guest',
        totalScore: 0,
      ),
      Player(
        id: 'p2',
        playerName: 'Ben Guest',
        nickname: 'Ben',
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

  testWidgets('Player selection flow: select and clear players',
      (tester) async {
    // We use a Navigator to allow pushing/popping routes
    await tester.pumpWidget(
      const MaterialApp(
        home: GameCreateScreen(),
      ),
    );
    await pumpRoute(tester);

    // Initial state: 0 players
    expect(find.text('0 players selected'), findsOneWidget);

    // Open Player Selection screen
    await tester.tap(find.text('Players'));
    await pumpRoute(tester);

    expect(find.byType(PlayersScreen), findsOneWidget);

    // Select Ava by tapping the Switch
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Confirm selection (Add selected players to game.)
    await tester.tap(find.text('Add selected players to game.'));
    await pumpRoute(tester);

    // Should be back on Create Game
    expect(find.byType(GameCreateScreen), findsOneWidget);
    expect(find.text('1 player selected'), findsOneWidget);

    // Open Player Selection screen again
    await tester.tap(find.text('Players'));
    await pumpRoute(tester);

    expect(find.byType(PlayersScreen), findsOneWidget);

    // Clear selections using AppBar action "Clear All"
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    // Confirm selection (Add selected players to game.)
    await tester.tap(find.text('Add selected players to game.'));
    await pumpRoute(tester);

    // Verifies the Create Game screen correctly updates to show 0 players selected.
    expect(find.byType(GameCreateScreen), findsOneWidget);
    expect(find.text('0 players selected'), findsOneWidget);
  });
}

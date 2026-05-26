import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/app_drawer_widget.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(MockFirebaseAuth());
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());

    final game = Game(
      id: 'recent_game_123',
      name: 'Test Completed Game',
      course: Course(id: 'c1', name: 'Test Course', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [PlayerGameInfo(playerId: 'p1', gameId: 'recent_game_123', scores: [2], totalScore: 2)],
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      scheduledTime: DateTime.now().subtract(const Duration(hours: 2)),
      completedTime: DateTime.now().subtract(const Duration(hours: 1)),
      status: 'completed',
    );

    SharedPreferences.setMockInitialValues({
      'recent_game_123': jsonEncode(game.toJson()),
    });
  });

  testWidgets('Guest drawer intercept displays prompt message on LoginScreen', (tester) async {
    // Pump a mock app shell with drawer
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        drawer: const AppDrawer(),
        body: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // Open the drawer
    final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Find the recent game in the drawer
    final recentGameTile = find.byKey(const Key('drawer-recent-recent_game_123'));
    expect(recentGameTile, findsOneWidget);

    // Tap it to trigger the intercept
    await tester.tap(recentGameTile);
    await tester.pumpAndSettle();

    // Verify it navigates to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Verify the specific context message banner is visible
    expect(find.text("Login or register to view your past game details and save your history to the cloud."), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}

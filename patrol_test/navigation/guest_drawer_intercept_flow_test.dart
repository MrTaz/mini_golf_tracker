// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
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

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
  });

  patrolTest('Guest drawer intercept displays prompt message on LoginScreen', ($) async {
    // Pump a mock app shell with drawer
    await $.pumpWidgetAndSettle(MaterialApp(
      home: Scaffold(
        drawer: const AppDrawer(),
        body: const HomeScreen(),
      ),
    ));

    // Open the drawer programmatically via ScaffoldState
    final scaffoldState = $.tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await $.pumpAndSettle();

    // Find the recent game in the drawer
    final recentGameTile = $(find.byKey(const Key('drawer-recent-recent_game_123')));
    expect(recentGameTile, findsOneWidget);

    // Tap it to trigger the intercept
    await recentGameTile.tap();
    await $.pumpAndSettle();

    // Verify it navigates to LoginScreen
    expect($(LoginScreen), findsOneWidget);

    // Verify the specific context message banner is visible
    expect($("Login or register to view your past game details and save your history to the cloud."), findsOneWidget);
    expect($(Icons.info_outline), findsOneWidget);
  });
}

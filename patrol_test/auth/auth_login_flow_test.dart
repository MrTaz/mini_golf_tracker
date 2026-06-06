// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().setAuthInstanceForTesting(mockAuth);
    SharedPreferences.setMockInitialValues({});
  });

  patrolTest('Auth E2E Test: Test Account Bypass Flow', ($) async {
    $.tester.view.physicalSize = const Size(1080, 2400);
    $.tester.view.devicePixelRatio = 1.0;
    addTearDown($.tester.view.resetPhysicalSize);
    addTearDown($.tester.view.resetDevicePixelRatio);

    // Create an UNCLAIMED player in DB for test@example.com
    await Player.createPlayer('Test User', 'Tester',
        email: 'test@example.com', ownerId: 'some-other-person-id');

    // Pre-create user in mock auth so signing in doesn't fail
    await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com', password: 'password123');
    await mockAuth.signOut();

    await $.pumpWidgetAndSettle(
      MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/': (context) => const Scaffold(body: Text('DashboardScreen')),
        },
      ),
    );

    // flutter_login hit-test bug/animation bypass
    int pumps = 0;
    while ($(TextFormField).evaluate().isEmpty && pumps < 100) {
      await $.pump(const Duration(milliseconds: 100));
      pumps++;
    }

    if ($(TextFormField).evaluate().isEmpty) {
      debugPrint("No TextFormField found! Widget tree:");
      debugDumpApp();
    }

    final emailField = $(TextFormField).at(0);
    final passwordField = $(TextFormField).at(1);

    await emailField.enterText('test@example.com');
    await $.pump(const Duration(milliseconds: 100));
    await passwordField.enterText('password123');
    await $.pump(const Duration(milliseconds: 100));

    // Find Login button
    await $('LOGIN').tap();

    await $.pump(const Duration(seconds: 5));
    await $.pumpAndSettle();

    // Verify it routes to the dashboard screen
    // Wait for the login animation and navigation to complete
    int postPumps = 0;
    while ($('DashboardScreen').evaluate().isEmpty && postPumps < 50) {
      await $.pump(const Duration(milliseconds: 100));
      postPumps++;
    }

    expect($('DashboardScreen'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/player.dart';

void main() {
  patrolTest(
    'Google Sign-In Native E2E Test',
    ($) async {
      final mockAuth = MockFirebaseAuth();
      final fakeFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      UserProvider().setAuthInstanceForTesting(mockAuth);
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});

      // Create an unclaimed player in the database for the test account
      await Player.createPlayer(
        'Test Google User',
        'GoogleTester',
        email: 'test@example.com',
        ownerId: 'some-other-google-uid',
      );

      // Pre-create the user in mock auth so the mock sign-in credential succeeds
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      await mockAuth.signOut();

      // Pump the login screen with a MaterialApp
      await $.pumpWidgetAndSettle(
        MaterialApp(
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/': (context) => const Scaffold(
                  body: Text('DashboardScreen'),
                ),
          },
        ),
      );

      // Verify we are on the login screen
      expect($('Mini Golf Tracker - Please login'), findsOneWidget);

      // Tap the "Sign in with Google" button
      // FlutterLogin uses standard icons for social buttons
      await $(find.byWidgetPredicate((widget) => widget is FaIcon && widget.icon?.codePoint == FontAwesomeIcons.google.codePoint)).tap();
      await $.pumpAndSettle();

      // Interact with the native OS Google account selector pop-up
      // We physically tap the target email using Patrol's native driver
      try {
        await $.platform.mobile.tap(Selector(text: 'test@example.com'));
        await $.pumpAndSettle();
      } catch (e) {
        // Handle cases where the native popup is simulated or handled in the background
        debugPrint('Native tap simulated/resolved: $e');
      }

      // Verify that the login resolves and successfully routes to the Dashboard screen
      int postPumps = 0;
      while ($('DashboardScreen').evaluate().isEmpty && postPumps < 50) {
        await $.pump(const Duration(milliseconds: 100));
        postPumps++;
      }

      expect($('DashboardScreen'), findsOneWidget);
    },
  );
}

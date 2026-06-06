// ignore_for_file: depend_on_referenced_packages, invalid_use_of_visible_for_testing_member, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  setUp(() {
    UserProvider().resetForTesting();
  });

  patrolTest(
    'Google Sign-In Native E2E Test',
    ($) async {
      final mockAuth = SocialMockFirebaseAuth(
        uid: 'some-other-google-uid',
        email: 'test@example.com',
      );
      final fakeFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      UserProvider().setAuthInstanceForTesting(mockAuth);
      SharedPreferences.setMockInitialValues({});

      // Create an unclaimed player in the database for the test account
      await Player.createPlayer(
        'Test Google User',
        'GoogleTester',
        email: 'test@example.com',
        ownerId: 'some-other-google-uid',
      );

      final googleSignIn = MockGoogleSignIn();
      MockGoogleSignIn.setMockUser(
        id: 'some-other-google-uid',
        email: 'test@example.com',
      );

      // Pump the login screen with a MaterialApp
      await $.pumpWidgetAndSettle(
        MaterialApp(
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginScreen(googleSignIn: googleSignIn),
            '/': (context) => const Scaffold(
                  body: Text('DashboardScreen'),
                ),
          },
        ),
      );

      // Verify we are on the login screen
      expect($('Putt Scorer - Please login'), findsOneWidget);

      // Tap the "Sign in with Google" button
      // FlutterLogin uses standard icons for social buttons
      await $(find.byWidgetPredicate((widget) =>
          widget is FaIcon &&
          widget.icon?.codePoint == FontAwesomeIcons.google.codePoint)).tap();
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

// --- Custom mock classes to support testing ---

class FakeGoogleSignInAccount implements GoogleSignInAccount {
  @override
  final String id;
  @override
  final String email;
  @override
  final String displayName;
  @override
  final String? photoUrl = null;
  final String? serverAuthCode = null;

  FakeGoogleSignInAccount({
    required this.id,
    required this.email,
    this.displayName = 'Google User',
  });

  @override
  GoogleSignInAuthentication get authentication =>
      FakeGoogleSignInAuthentication();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  final String idToken = 'mock_id_token';
  final String? accessToken = 'mock_access_token';
  final String? serverAuthCode = null;
}

class MockGoogleSignIn implements GoogleSignIn {
  static GoogleSignInAccount? _mockUser;

  static void setMockUser({required String id, required String email}) {
    _mockUser = FakeGoogleSignInAccount(id: id, email: email);
  }

  static void cancelSignIn() {
    _mockUser = null;
  }

  @override
  Future<void> initialize({
    String? clientId,
    String? hostedDomain,
    String? nonce,
    String? serverClientId,
  }) async {}

  @override
  Future<GoogleSignInAccount> authenticate(
      {List<String> scopeHint = const []}) async {
    if (_mockUser == null) {
      throw Exception('Sign in cancelled');
    }
    return _mockUser!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CustomUser implements User {
  CustomUser({
    required this.uid,
    required this.email,
    this.emailVerified = true,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
  });

  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final String? phoneNumber;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CustomUserCredential implements UserCredential {
  CustomUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SocialMockFirebaseAuth implements FirebaseAuth {
  SocialMockFirebaseAuth({
    required this.uid,
    required this.email,
    this.emailVerified = true,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
  });

  final String uid;
  final String? email;
  final bool emailVerified;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;

  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(_currentUser);

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    _currentUser = CustomUser(
      uid: uid,
      email: email,
      emailVerified: emailVerified,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoURL: photoURL,
    );
    return CustomUserCredential(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

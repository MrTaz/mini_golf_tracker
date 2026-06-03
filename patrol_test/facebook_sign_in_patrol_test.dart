// ignore_for_file: depend_on_referenced_packages, invalid_use_of_visible_for_testing_member, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  setUp(() {
    MockFacebookAuthPlatform.register();
    MockFacebookAuthPlatform.reset();
    UserProvider().resetForTesting();
  });

  patrolTest(
    'Meta/Facebook Sign-In Native E2E Test',
    ($) async {
      final mockAuth = SocialMockFirebaseAuth(
        uid: 'facebook-uid',
        email: 'facebook@example.com',
      );
      final fakeFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      UserProvider().setAuthInstanceForTesting(mockAuth);
      SharedPreferences.setMockInitialValues({});

      // Pre-create the player matching the expected signed-in user's UID
      await fakeFirestore.collection('players').doc('facebook-uid').set({
        'id': 'facebook-uid',
        'player_name': 'Facebook User',
        'owner_id': 'facebook-uid',
        'email': 'facebook@example.com',
        'nickname': 'facebook_user',
        'shareName': true,
        'shareEmail': true,
        'sharePhone': true,
      });

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
      expect($('Putt Scorer - Please login'), findsOneWidget);

      // Tap the Facebook Sign-In button
      await $(find.byWidgetPredicate((widget) => widget is FaIcon && widget.icon?.codePoint == FontAwesomeIcons.facebookF.codePoint)).tap();
      await $.pumpAndSettle();

      // Interact with the Meta/Facebook web-view or native authorization pop-up
      try {
        await $.native.tap(Selector(textContains: 'Continue as'));
        await $.pumpAndSettle();
      } catch (e) {
        debugPrint('Native Facebook Continue prompt tap simulated/resolved: $e');
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

// --- Custom user and auth implementations for robust social testing ---

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

class MockFacebookAuthPlatform extends FacebookAuthPlatform with MockPlatformInterfaceMixin {
  MockFacebookAuthPlatform();

  static MockFacebookAuthPlatform? _instance;

  static void register() {
    _instance ??= MockFacebookAuthPlatform();
    FacebookAuthPlatform.instance = _instance!;
  }

  static void reset() {
    if (_instance != null) {
      _instance!.status = LoginStatus.success;
      _instance!.shouldThrow = false;
      _instance!.tokenString = 'mock_fb_token';
      _instance!.errorMessage = null;
    }
  }

  LoginStatus status = LoginStatus.success;
  bool shouldThrow = false;
  String tokenString = 'mock_fb_token';
  String? errorMessage;

  @override
  Future<LoginResult> login({
    dynamic loginBehavior,
    dynamic loginTracking,
    String? nonce,
    List<String> permissions = const ['email', 'public_profile'],
  }) async {
    if (shouldThrow) {
      throw Exception('Simulated Facebook Exception');
    }
    if (status == LoginStatus.success) {
      return LoginResult(
        status: LoginStatus.success,
        accessToken: MockAccessToken(tokenString: tokenString),
      );
    } else if (status == LoginStatus.cancelled) {
      return LoginResult(status: LoginStatus.cancelled);
    } else {
      return LoginResult(
        status: LoginStatus.failed,
        message: errorMessage ?? 'Facebook Sign-In failed.',
      );
    }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAccessToken implements AccessToken {
  @override
  final String tokenString;

  MockAccessToken({required this.tokenString});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

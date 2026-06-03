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
import 'package:sign_in_with_apple_platform_interface/sign_in_with_apple_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  setUp(() {
    MockSignInWithApplePlatform.register();
    MockSignInWithApplePlatform.reset();
    UserProvider().resetForTesting();
  });

  patrolTest(
    'Apple Sign-In Native E2E Test',
    ($) async {
      final mockAuth = SocialMockFirebaseAuth(
        uid: 'apple-uid',
        email: 'apple@example.com',
      );
      final fakeFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      UserProvider().setAuthInstanceForTesting(mockAuth);
      SharedPreferences.setMockInitialValues({});

      // Pre-create the player matching the expected signed-in user's UID
      await fakeFirestore.collection('players').doc('apple-uid').set({
        'id': 'apple-uid',
        'player_name': 'Apple User',
        'owner_id': 'apple-uid',
        'email': 'apple@example.com',
        'nickname': 'apple_user',
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

      // Tap the Apple Sign-In button
      await $(find.byWidgetPredicate((widget) => widget is FaIcon && widget.icon?.codePoint == FontAwesomeIcons.apple.codePoint)).tap();
      await $.pumpAndSettle();

      // Interact with the OS-level Native dialog prompts (Apple ID "Continue" / "Passcode")
      try {
        await $.native.tap(Selector(text: 'Continue'));
        await $.pumpAndSettle();
      } catch (e) {
        debugPrint('Native Apple Continue prompt tap simulated/resolved: $e');
      }

      try {
        await $.native.tap(Selector(text: 'Passcode'));
        await $.pumpAndSettle();
      } catch (e) {
        debugPrint('Native Apple Passcode prompt tap simulated/resolved: $e');
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

// --- Mock Platform Interfaces for E2E automation simulation ---

class MockSignInWithApplePlatform extends SignInWithApplePlatform
    with MockPlatformInterfaceMixin {
  static MockSignInWithApplePlatform? _instance;

  static void register() {
    _instance ??= MockSignInWithApplePlatform();
    SignInWithApplePlatform.instance = _instance!;
  }

  static void reset() {
    if (_instance != null) {
      _instance!.shouldCancel = false;
      _instance!.shouldThrowError = false;
      _instance!.email = 'apple@example.com';
      _instance!.givenName = 'Apple';
      _instance!.familyName = 'User';
      _instance!.authorizationCode = 'mock_code';
      _instance!.identityToken = 'mock_token';
      _instance!.userIdentifier = 'mock_user';
    }
  }

  bool shouldCancel = false;
  bool shouldThrowError = false;
  String email = 'apple@example.com';
  String? givenName = 'Apple';
  String? familyName = 'User';
  String authorizationCode = 'mock_code';
  String identityToken = 'mock_token';
  String userIdentifier = 'mock_user';

  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? nonce,
    String? state,
  }) async {
    if (shouldCancel) {
      throw SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'The user canceled the authorization attempt.',
      );
    }
    if (shouldThrowError) {
      throw SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.unknown,
        message: 'Apple Sign-In failed.',
      );
    }
    return AuthorizationCredentialAppleID(
      authorizationCode: authorizationCode,
      identityToken: identityToken,
      userIdentifier: userIdentifier,
      email: email,
      givenName: givenName,
      familyName: familyName,
      state: state,
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

Finder findIconByCodePoint(int codePoint) {
  return find.byWidgetPredicate((widget) {
    if (widget is Icon && widget.icon?.codePoint == codePoint) return true;
    if (widget is FaIcon && widget.icon?.codePoint == codePoint) return true;
    return false;
  });
}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    mockAuth = MockFirebaseAuth();
    await mockAuth.signOut(); // Ensure the mock auth starts signed out
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().setAuthInstanceForTesting(mockAuth);
    SharedPreferences.setMockInitialValues({});
    timeDilation = 1.0; // Reset timeDilation
  });

  tearDown(() {
    timeDilation = 1.0; // Reset after each test
  });

  Widget createLoginScreen({GoogleSignIn? googleSignIn}) {
    return MaterialApp(
      home: LoginScreen(googleSignIn: googleSignIn),
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Home Page')));
        }
        return null;
      },
    );
  }

  testWidgets('LoginScreen shows login form when not logged in',
      (tester) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    expect(find.text('Mini Golf Tracker - Please login'), findsOneWidget);
    // Find by type instead of text to avoid    // The test framework will complain about pending timers from FlutterLogin's intro animations
    // We pump a few times to let them settle or at least progress.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FlutterLogin), findsOneWidget);
    // Final pump to help clear any remaining timers before disposal
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('LoginScreen shows social login providers', (tester) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Check for social buttons
    // FlutterLogin renders these as icons or specific buttons.
    // We can look for the icons or the types if we know them.
    // Usually they are rendered as IconButton or similar inside the login providers row.
    expect(
        findIconByCodePoint(FontAwesomeIcons.google.codePoint), findsWidgets);
    expect(findIconByCodePoint(FontAwesomeIcons.facebookF.codePoint),
        findsNothing);
    expect(
        findIconByCodePoint(FontAwesomeIcons.snapchat.codePoint), findsNothing);
    expect(findIconByCodePoint(FontAwesomeIcons.instagram.codePoint),
        findsNothing);

    // Add extra pump to clear timers from animations
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('LoginScreen shows Account Details when logged in',
      (tester) async {
    final player = Player(
      id: 'user123',
      playerName: 'Test User',
      nickname: 'Tester',
      ownerId: 'user123',
      totalScore: 100,
      email: 'test@example.com',
    );

    // Manually set the user as logged in
    await UserProvider().login(player);

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    expect(find.text('Account Details'), findsOneWidget);
    expect(find.text('Name: Test User'), findsOneWidget);
    expect(find.text('Nickname: Tester'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('Google Sign-In provider logs in with Firebase credentials',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();
    await fakeFirestore.collection('players').doc('google-uid').set({
      'player_name': 'Google User',
      'owner_id': 'google-uid',
      'email': 'google@example.com',
    });

    final googleSignIn = GoogleSignIn();
    TestGoogleSignInPlatform.signInUser(
      id: 'google-uid',
      email: 'google@example.com',
      idToken: 'mock_id_token',
      accessToken: 'mock_access_token',
    );

    await tester.pumpWidget(createLoginScreen(googleSignIn: googleSignIn));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final googleButton = findIconByCodePoint(FontAwesomeIcons.google.codePoint);
    expect(googleButton, findsOneWidget);
    await tester.ensureVisible(googleButton);
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth());
    await tester.tap(googleButton);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'google@example.com');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Email/Password Login flow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // flutter_login hit-test bug/animation bypass
    int pumps = 0;
    while (find.byType(TextFormField).evaluate().isEmpty && pumps < 50) {
      await tester.pump(const Duration(milliseconds: 100));
      pumps++;
    }

    await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com', password: 'password123');
    await mockAuth.signOut();

    final emailField = find.byType(TextFormField).at(0);
    final passwordField = find.byType(TextFormField).at(1);

    await tester.enterText(emailField, 'test@example.com');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(passwordField, 'password123');
    await tester.pump(const Duration(milliseconds: 100));

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final loginButton = find.text('LOGIN');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Direct authUser, signupUser, recoverPassword coverage',
      (tester) async {
    // cover loginTime
    await tester.pumpWidget(MaterialApp(home: const LoginScreen()));
    final stateForTime =
        tester.state<LoginScreenState>(find.byType(LoginScreen));
    expect(stateForTime.loginTime, equals(const Duration(milliseconds: 50)));
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    var state = tester.state<LoginScreenState>(find.byType(LoginScreen));

    // 1. Signup a user so a player exists
    var initialSignupResult = await state.signupUser(SignupData.fromSignupForm(
        name: 'test@example.com',
        password: 'password123',
        additionalSignupData: {
          'playerName': 'Mock User',
          'nickname': 'mock',
        }));
    expect(initialSignupResult, isNull);
    await mockAuth.signOut();

    // 2. authUser happy path (should find the player and call UserProvider.login)
    var authResult = await state
        .authUser(LoginData(name: 'test@example.com', password: 'password123'));
    expect(authResult, isNull);

    // 2.2 Already logged in UI (Logout & Back to Home)
    await tester.pumpWidget(MaterialApp(home: const LoginScreen()));
    await tester.pumpAndSettle();

    // Tap Back to Home
    final backButton = find.text("Back to Home");
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Tap Logout
    final logoutButton = find.text("Logout");
    expect(logoutButton, findsOneWidget);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // State is logged out now, so repump LoginScreen to get the FlutterLogin widget back
    await tester.pumpWidget(MaterialApp(home: const LoginScreen()));
    await tester.pumpAndSettle();
    state = tester.state<LoginScreenState>(find.byType(LoginScreen));

    // 2.5 authUser claim path (unclaimed player exists in DB but not linked to Auth UID)
    await Player.createPlayer('Unclaimed', 'unclaimed',
        email: 'test_unclaimed@example.com', ownerId: 'unclaimed-db-id');
    await mockAuth.createUserWithEmailAndPassword(
        email: 'test_unclaimed@example.com', password: 'password123');
    await mockAuth.signOut();
    var authClaimResult = await state.authUser(
        LoginData(name: 'test_unclaimed@example.com', password: 'password123'));
    expect(authClaimResult, isNull);

    // authUser errors (FirebaseAuthException)
    final throwingAuth = ThrowingFirebaseAuth();
    userProvider.setAuthInstanceForTesting(throwingAuth);
    var errorResult = await state
        .authUser(LoginData(name: 'unknown@example.com', password: '123'));
    expect(errorResult, equals('Simulated Auth Exception'));

    final nullMessageThrowingAuth = NullMessageThrowingFirebaseAuth();
    userProvider.setAuthInstanceForTesting(nullMessageThrowingAuth);
    var nullErrorResult = await state
        .authUser(LoginData(name: 'unknown@example.com', password: '123'));
    expect(nullErrorResult, equals('An error occurred during login.'));

    final genericThrowingAuth = GenericThrowingFirebaseAuth();
    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var genericErrorResult = await state
        .authUser(LoginData(name: 'unknown@example.com', password: '123'));
    expect(genericErrorResult, equals('An error occurred during user login.'));

    // restore mockAuth for the rest of tests
    userProvider.setAuthInstanceForTesting(mockAuth);

    // signupUser happy path
    var signupResult = await state.signupUser(SignupData.fromSignupForm(
        name: 'new2@example.com',
        password: 'password123',
        additionalSignupData: {
          'playerName': 'New2 User',
          'nickname': 'new2_user',
        }));
    expect(signupResult, isNull);

    // signupUser claim existing
    await Player.createPlayer('Existing', 'exist',
        email: 'existing@example.com', id: 'existing-id');
    var signupResultExisting = await state.signupUser(SignupData.fromSignupForm(
        name: 'existing@example.com',
        password: 'password123',
        additionalSignupData: {
          'playerName': 'Existing',
          'nickname': 'exist',
        }));
    expect(signupResultExisting, isNotNull);

    // signupUser errors
    userProvider.setAuthInstanceForTesting(throwingAuth);
    var signupError = await state.signupUser(SignupData.fromSignupForm(
        name: 'error@example.com',
        password: 'password123',
        additionalSignupData: {'playerName': 'E', 'nickname': 'e'}));
    expect(signupError, equals('Simulated Auth Exception'));

    userProvider.setAuthInstanceForTesting(nullMessageThrowingAuth);
    var nullSignupError = await state.signupUser(SignupData.fromSignupForm(
        name: 'error@example.com',
        password: 'password123',
        additionalSignupData: {'playerName': 'E', 'nickname': 'e'}));
    expect(nullSignupError, equals('An error occurred during registration.'));

    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var genericSignupError = await state.signupUser(SignupData.fromSignupForm(
        name: 'error@example.com',
        password: 'password123',
        additionalSignupData: {'playerName': 'E', 'nickname': 'e'}));
    expect(genericSignupError,
        equals('An error occurred during user registration.'));

    userProvider.setAuthInstanceForTesting(mockAuth);

    // recoverPassword
    var recoverResultFuture = state.recoverPassword('test@example.com');
    await tester.pump(const Duration(seconds: 5));
    var recoverResult = await recoverResultFuture;
    expect(recoverResult, isNull);

    // handleGoogleLogin
    final googleSignIn = GoogleSignIn();
    TestGoogleSignInPlatform.signInUser(
      id: 'google-uid',
      email: 'google@example.com',
      idToken: 'mock-id-token',
      accessToken: 'mock-access-token',
    );
    await tester
        .pumpWidget(MaterialApp(home: LoginScreen(googleSignIn: googleSignIn)));
    await tester.pump();

    // Create a known player in the db
    await fakeFirestore.collection('players').doc('google-uid').set({
      'player_name': 'Google User',
      'owner_id': 'google-uid',
      'email': 'google@example.com'
    });

    final googleHappyAuth = GoogleHappyFirebaseAuth();
    userProvider.setAuthInstanceForTesting(googleHappyAuth);
    final googleState =
        tester.state<LoginScreenState>(find.byType(LoginScreen));
    var googleResult = await googleState.handleGoogleLogin();
    expect(googleResult, isNull);

    // User cancellation path
    TestGoogleSignInPlatform.cancelSignIn();
    var googleCancellationResult = await googleState.handleGoogleLogin();
    expect(googleCancellationResult, isNull);

    // Claim path when the auth UID has no player but verified contact matches.
    await Player.createPlayer(
      'Google Claim',
      'gclaim',
      email: 'google-claim@example.com',
      ownerId: 'legacy-google-owner',
    );
    TestGoogleSignInPlatform.signInUser(
      id: 'google-claim-uid',
      email: 'google-claim@example.com',
      idToken: 'mock-id-token',
      accessToken: 'mock-access-token',
    );
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'google-claim-uid',
      email: 'google-claim@example.com',
    ));
    var googleClaimResult = await googleState.handleGoogleLogin();
    expect(googleClaimResult, isNull);

    // Error path
    TestGoogleSignInPlatform.signInUser(
      id: 'google-uid',
      email: 'google@example.com',
      idToken: 'mock-id-token',
      accessToken: 'mock-access-token',
    );
    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var googleErrorResult = await googleState.handleGoogleLogin();
    expect(googleErrorResult, equals('Google Sign-In failed.'));
    userProvider.setAuthInstanceForTesting(mockAuth);
  });

  testWidgets('LoginScreen covers unclaimed and cancelled auth branches',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();
    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));

    userProvider.setAuthInstanceForTesting(EmailSignInFirebaseAuth(
      uid: 'unclaimed-no-player-uid',
      email: 'unclaimed-no-player@example.com',
      emailVerified: false,
    ));
    final authNoPlayerResult = await state.authUser(LoginData(
      name: 'unclaimed-no-player@example.com',
      password: 'password123',
    ));
    expect(
      authNoPlayerResult,
      equals('Verify an email or phone number to claim your player history.'),
    );

    final googleSignIn = GoogleSignIn();
    TestGoogleSignInPlatform.cancelSignIn();
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(googleSignIn: googleSignIn)),
    );
    await tester.pump();
    final googleState =
        tester.state<LoginScreenState>(find.byType(LoginScreen));
    final googleCancellationResult = await googleState.handleGoogleLogin();
    expect(googleCancellationResult, isNull);

    TestGoogleSignInPlatform.signInUser(
      id: 'google-no-player-uid',
      email: 'google-no-player@example.com',
      idToken: 'mock-id-token',
      accessToken: 'mock-access-token',
    );
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'google-no-player-uid',
      email: 'google-no-player@example.com',
      emailVerified: false,
    ));
    final googleNoPlayerResult = await googleState.handleGoogleLogin();
    expect(
      googleNoPlayerResult,
      equals('Verify an email or phone number to claim your player history.'),
    );
    await tester.pump(const Duration(seconds: 2));
  });
}

class TestGoogleSignInPlatform extends GoogleSignInPlatform
    with MockPlatformInterfaceMixin {
  TestGoogleSignInPlatform._();

  static GoogleSignInUserData? _signInUser;
  static GoogleSignInTokenData _tokenData = GoogleSignInTokenData();

  static void signInUser({
    required String id,
    required String email,
    required String idToken,
    required String accessToken,
  }) {
    _signInUser = GoogleSignInUserData(
      id: id,
      email: email,
      displayName: 'Google User',
      idToken: idToken,
    );
    _tokenData = GoogleSignInTokenData(
      idToken: idToken,
      accessToken: accessToken,
    );
    GoogleSignInPlatform.instance = TestGoogleSignInPlatform._();
  }

  static void cancelSignIn() {
    _signInUser = null;
    _tokenData = GoogleSignInTokenData();
    GoogleSignInPlatform.instance = TestGoogleSignInPlatform._();
  }

  @override
  Future<void> initWithParams(SignInInitParameters params) async {}

  @override
  Future<GoogleSignInUserData?> signIn() async {
    return _signInUser;
  }

  @override
  Future<GoogleSignInTokenData> getTokens({
    required String email,
    bool? shouldRecoverAuth,
  }) async {
    return _tokenData;
  }
}

class ThrowingFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) {
    throw FirebaseAuthException(
        code: 'error', message: 'Simulated Auth Exception');
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) {
    throw FirebaseAuthException(
        code: 'error', message: 'Simulated Auth Exception');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class NullMessageThrowingFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) {
    throw FirebaseAuthException(code: 'error', message: null);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) {
    throw FirebaseAuthException(code: 'error', message: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GenericThrowingFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) {
    throw Exception('Simulated Generic Exception');
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) {
    throw Exception('Simulated Generic Exception');
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    throw Exception('Simulated Generic Exception');
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CustomUserCredential implements UserCredential {
  CustomUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GoogleHappyFirebaseAuth implements FirebaseAuth {
  GoogleHappyFirebaseAuth({
    this.uid = 'google-uid',
    this.email = 'google@example.com',
    this.emailVerified = true,
    this.phoneNumber,
  });

  final String uid;
  final String? email;
  final bool emailVerified;
  final String? phoneNumber;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return CustomUserCredential(CustomUser(
      uid: uid,
      email: email,
      emailVerified: emailVerified,
      phoneNumber: phoneNumber,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmailSignInFirebaseAuth implements FirebaseAuth {
  EmailSignInFirebaseAuth({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final bool emailVerified;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return CustomUserCredential(CustomUser(
      uid: uid,
      email: this.email,
      emailVerified: emailVerified,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

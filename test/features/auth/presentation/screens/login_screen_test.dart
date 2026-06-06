import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';
import 'package:sign_in_with_apple_platform_interface/sign_in_with_apple_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';

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
    MockSignInWithApplePlatform.register();
    MockSignInWithApplePlatform.reset();
    MockFacebookAuthPlatform.register();
    MockFacebookAuthPlatform.reset();
  });

  tearDown(() {
    timeDilation = 1.0; // Reset after each test
  });

  Widget createLoginScreen(
      {GoogleSignIn? googleSignIn, String? promptMessage}) {
    return MaterialApp(
      home:
          LoginScreen(googleSignIn: googleSignIn, promptMessage: promptMessage),
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

    expect(find.text('Putt Scorer - Please login'), findsOneWidget);
    // Find by type instead of text to avoid    // The test framework will complain about pending timers from FlutterLogin's intro animations
    // We pump a few times to let them settle or at least progress.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FlutterLogin), findsOneWidget);
    // Final pump to help clear any remaining timers before disposal
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('LoginScreen shows promptMessage when provided', (tester) async {
    await tester
        .pumpWidget(createLoginScreen(promptMessage: 'Important Message!'));
    await tester.pumpAndSettle();

    expect(find.text('Important Message!'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('LoginScreen does not show banner when promptMessage is null',
      (tester) async {
    await tester.pumpWidget(createLoginScreen(promptMessage: null));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.info_outline), findsNothing);
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
        findsWidgets);
    expect(
        findIconByCodePoint(FontAwesomeIcons.snapchat.codePoint), findsWidgets);
    expect(findIconByCodePoint(FontAwesomeIcons.instagram.codePoint),
        findsWidgets);

    // Add extra pump to clear timers from animations
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Social login placeholders return Not implemented yet',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    expect(
        await state.handleNotImplementedLogin(), equals('Not implemented yet'));

    final facebookButton =
        findIconByCodePoint(FontAwesomeIcons.facebookF.codePoint);
    expect(facebookButton, findsOneWidget);

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

    final googleSignIn = MockGoogleSignIn();
    MockGoogleSignIn.setMockUser(
      id: 'google-uid',
      email: 'google@example.com',
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
    await tester.tap(loginButton, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Direct authUser, signupUser, recoverPassword coverage',
      (tester) async {
    // cover loginTime
    final googleSignIn = MockGoogleSignIn();
    await tester
        .pumpWidget(MaterialApp(home: LoginScreen(googleSignIn: googleSignIn)));
    final stateForTime =
        tester.state<LoginScreenState>(find.byType(LoginScreen));
    expect(stateForTime.loginTime, equals(const Duration(milliseconds: 50)));
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen(googleSignIn: googleSignIn));
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
    await tester
        .pumpWidget(MaterialApp(home: LoginScreen(googleSignIn: googleSignIn)));
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
    await tester
        .pumpWidget(MaterialApp(home: LoginScreen(googleSignIn: googleSignIn)));
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
    MockGoogleSignIn.setMockUser(
      id: 'google-uid',
      email: 'google@example.com',
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
    MockGoogleSignIn.cancelSignIn();
    var googleCancellationResult = await googleState.handleGoogleLogin();
    expect(googleCancellationResult, equals('Google Sign-In failed.'));

    // Claim path when the auth UID has no player but verified contact matches.
    await Player.createPlayer(
      'Google Claim',
      'gclaim',
      email: 'google-claim@example.com',
      ownerId: 'legacy-google-owner',
    );
    MockGoogleSignIn.setMockUser(
      id: 'google-claim-uid',
      email: 'google-claim@example.com',
    );
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'google-claim-uid',
      email: 'google-claim@example.com',
    ));
    var googleClaimResult = await googleState.handleGoogleLogin();
    expect(googleClaimResult, isNull);

    // Error path
    MockGoogleSignIn.setMockUser(
      id: 'google-uid',
      email: 'google@example.com',
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

    final googleSignIn = MockGoogleSignIn();
    await tester.pumpWidget(createLoginScreen(googleSignIn: googleSignIn));
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

    MockGoogleSignIn.cancelSignIn();
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(googleSignIn: googleSignIn)),
    );
    await tester.pump();
    final googleState =
        tester.state<LoginScreenState>(find.byType(LoginScreen));
    final googleCancellationResult = await googleState.handleGoogleLogin();
    expect(googleCancellationResult, equals('Google Sign-In failed.'));

    MockGoogleSignIn.setMockUser(
      id: 'google-no-player-uid',
      email: 'google-no-player@example.com',
    );
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'google-no-player-uid',
      email: 'google-no-player@example.com',
      emailVerified: false,
      photoURL: 'https://example.com/avatar.jpg',
      displayName: 'Google No Player Name',
    ));
    final googleNoPlayerResult = await googleState.handleGoogleLogin();
    expect(googleNoPlayerResult, isNull);

    // If there is an existing unclaimed candidate and email is not verified, it should require verification.
    await Player.createPlayer(
      'Existing Guest',
      'guest',
      email: 'google-unverified-guest@example.com',
      ownerId: 'some-owner-id',
    );
    MockGoogleSignIn.setMockUser(
      id: 'google-unverified-guest-uid',
      email: 'google-unverified-guest@example.com',
    );
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'google-unverified-guest-uid',
      email: 'google-unverified-guest@example.com',
      emailVerified: false,
    ));
    final googleUnverifiedGuestResult = await googleState.handleGoogleLogin();
    expect(
      googleUnverifiedGuestResult,
      equals('Verify an email or phone number to claim your player history.'),
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Google Sign-In initialization is covered', (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleGoogleLogin();
    expect(result, equals('Google Sign-In failed.'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apple Sign-In: successful login with existing Firestore player',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Setup an existing player in firestore
    await fakeFirestore.collection('players').doc('apple-uid').set({
      'player_name': 'Apple User',
      'owner_id': 'apple-uid',
      'email': 'apple@example.com',
    });

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'apple-uid',
      email: 'apple@example.com',
    ));

    final result = await state.handleAppleLogin();
    expect(result, isNull);
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'apple@example.com');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Apple Sign-In: successful login and creates new social profile when no player exists',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'new-apple-uid',
      email: 'new-apple@example.com',
      displayName: 'Apple User',
    ));

    final result = await state.handleAppleLogin();
    expect(result, isNull);
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'new-apple@example.com');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Apple Sign-In: handles existing unclaimed player matching contact email (pending claim)',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Create an unclaimed player in Firestore
    await Player.createPlayer(
      'Unclaimed Apple Player',
      'unclaimedapple',
      email: 'unclaimed-apple@example.com',
      ownerId: 'unclaimed-apple-owner-id',
    );

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'new-apple-uid',
      email: 'unclaimed-apple@example.com',
      emailVerified: false,
    ));

    final result = await state.handleAppleLogin();
    expect(
        result,
        equals(
            'Verify an email or phone number to claim your player history.'));
    expect(userProvider.loggedInUser, isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apple Sign-In: graceful cancellation handling', (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Configure the mock to throw cancellation exception
    final mockPlatform =
        SignInWithApplePlatform.instance as MockSignInWithApplePlatform;
    mockPlatform.shouldCancel = true;

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleAppleLogin();
    expect(result, equals('Apple Sign-In was cancelled.'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apple Sign-In: non-cancellation exception handling',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Configure the mock to throw other authorization exception
    final mockPlatform =
        SignInWithApplePlatform.instance as MockSignInWithApplePlatform;
    mockPlatform.shouldThrowError = true;

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleAppleLogin();
    expect(result, equals('Apple Sign-In failed: Apple Sign-In failed.'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apple Sign-In: generic/other error handling', (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Set FirebaseAuth to throw a generic error
    userProvider.setAuthInstanceForTesting(GenericThrowingFirebaseAuth());

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleAppleLogin();
    expect(result, equals('Apple Sign-In failed.'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apple Sign-In: fallback to New User when names are null',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Set mock Apple details to null
    final mockPlatform =
        SignInWithApplePlatform.instance as MockSignInWithApplePlatform;
    mockPlatform.givenName = null;
    mockPlatform.familyName = null;
    mockPlatform.email = 'apple-fallback@example.com';

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'fallback-apple-uid',
      email: 'apple-fallback@example.com',
      photoURL: 'https://example.com/apple_avatar.jpg',
    ));

    final result = await state.handleAppleLogin();
    expect(result, isNull);
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.playerName, equals('New User'));
    expect(userProvider.loggedInUser!.avatarImageLocation,
        equals('https://example.com/apple_avatar.jpg'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apple Sign-In: fallback to user_id when displayName is empty',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Set mock Apple details to empty/null
    final mockPlatform =
        SignInWithApplePlatform.instance as MockSignInWithApplePlatform;
    mockPlatform.givenName = '';
    mockPlatform.familyName = '';
    mockPlatform.email = 'apple-empty@example.com';

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'empty-apple-uid',
      email: 'apple-empty@example.com',
      displayName: '',
    ));

    final result = await state.handleAppleLogin();
    expect(result, isNull);
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.nickname, equals('user_empty'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Facebook Sign-In: successful login with existing Firestore player',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Setup an existing player in firestore
    await fakeFirestore.collection('players').doc('facebook-uid').set({
      'player_name': 'Facebook User',
      'owner_id': 'facebook-uid',
      'email': 'facebook@example.com',
    });

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'facebook-uid',
      email: 'facebook@example.com',
    ));

    final result = await state.handleFacebookLogin();
    expect(result, isNull);
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'facebook@example.com');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Facebook Sign-In: successful login and creates new social profile when no player exists',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'new-facebook-uid',
      email: 'new-facebook@example.com',
      displayName: 'FB User',
      photoURL: 'https://example.com/avatar.jpg',
    ));

    final result = await state.handleFacebookLogin();
    expect(result, isNull);
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'new-facebook@example.com');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Facebook Sign-In: handles existing unclaimed player matching contact email (pending claim)',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Create an unclaimed player in Firestore
    await Player.createPlayer(
      'Unclaimed FB Player',
      'unclaimedfb',
      email: 'unclaimed-fb@example.com',
      ownerId: 'unclaimed-fb-owner-id',
    );

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    userProvider.setAuthInstanceForTesting(GoogleHappyFirebaseAuth(
      uid: 'new-facebook-uid',
      email: 'unclaimed-fb@example.com',
      emailVerified: false,
    ));

    final result = await state.handleFacebookLogin();
    expect(
        result,
        equals(
            'Verify an email or phone number to claim your player history.'));
    expect(userProvider.loggedInUser, isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Facebook Sign-In: graceful cancellation handling',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Configure the mock to throw cancellation exception/status
    MockFacebookAuthPlatform.reset();
    MockFacebookAuthPlatform._instance!.status = LoginStatus.cancelled;

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleFacebookLogin();
    expect(result, equals('Facebook Sign-In was cancelled.'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Facebook Sign-In: non-cancellation / failed status handling',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Configure the mock to return failed status
    MockFacebookAuthPlatform.reset();
    MockFacebookAuthPlatform._instance!.status = LoginStatus.failed;
    MockFacebookAuthPlatform._instance!.errorMessage = 'Custom FB Error';

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleFacebookLogin();
    expect(result, equals('Custom FB Error'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Facebook Sign-In: generic / exception error handling',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    // Configure the mock to throw an exception
    MockFacebookAuthPlatform.reset();
    MockFacebookAuthPlatform._instance!.shouldThrow = true;

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
    final result = await state.handleFacebookLogin();
    expect(result, equals('Facebook Sign-In failed.'));
    await tester.pump(const Duration(seconds: 5));
  });
}

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

class GoogleHappyFirebaseAuth implements FirebaseAuth {
  GoogleHappyFirebaseAuth({
    this.uid = 'google-uid',
    this.email = 'google@example.com',
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
      displayName: displayName,
      photoURL: photoURL,
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

class MockFacebookAuthPlatform extends FacebookAuthPlatform {
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

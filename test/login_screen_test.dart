import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
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

  Widget createLoginScreen({AuthCredential? mockGoogleCredential}) {
    return MaterialApp(
      home: LoginScreen(mockGoogleCredential: mockGoogleCredential),
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
    expect(findIconByCodePoint(FontAwesomeIcons.google.codePoint), findsWidgets);
    expect(findIconByCodePoint(FontAwesomeIcons.facebookF.codePoint), findsWidgets);
    expect(findIconByCodePoint(FontAwesomeIcons.snapchat.codePoint), findsWidgets);
    expect(findIconByCodePoint(FontAwesomeIcons.instagram.codePoint), findsWidgets);

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

  testWidgets('Social login simulation flows - Google Sign-In coverage', (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    final mockCredential = GoogleAuthProvider.credential(idToken: 'mock_id_token', accessToken: 'mock_access_token');
    await tester.pumpWidget(createLoginScreen(mockGoogleCredential: mockCredential));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final googleButton = findIconByCodePoint(FontAwesomeIcons.google.codePoint);
    expect(googleButton, findsOneWidget);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser, isNotNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Social login simulation flows - Facebook Sign-In',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Force the 1-second Future.delayed to fire and complete the intro animation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Find the Facebook login button and tap it
    final facebookButton = findIconByCodePoint(FontAwesomeIcons.facebookF.codePoint);
    expect(facebookButton, findsOneWidget);
    await tester.ensureVisible(facebookButton);
    await tester.tap(facebookButton);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'facebook_user@example.com');

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Social login simulation flows - Snapchat Sign-In',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Force the 1-second Future.delayed to fire and complete the intro animation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Find the Snapchat login button and tap it
    final snapchatButton = findIconByCodePoint(FontAwesomeIcons.snapchat.codePoint);
    expect(snapchatButton, findsOneWidget);
    await tester.ensureVisible(snapchatButton);
    await tester.tap(snapchatButton);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'snapchat_user@example.com');

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Social login simulation flows - Instagram Sign-In',
      (tester) async {
    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Force the 1-second Future.delayed to fire and complete the intro animation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Find the Instagram login button and tap it
    final instagramButton = findIconByCodePoint(FontAwesomeIcons.instagram.codePoint);
    expect(instagramButton, findsOneWidget);
    await tester.ensureVisible(instagramButton);
    await tester.tap(instagramButton);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'instagram_user@example.com');

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
    while(find.byType(TextFormField).evaluate().isEmpty && pumps < 50) {
      await tester.pump(const Duration(milliseconds: 100));
      pumps++;
    }

    await mockAuth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password123');
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

  testWidgets('Direct authUser, signupUser, recoverPassword coverage', (tester) async {
    // cover loginTime
    await tester.pumpWidget(MaterialApp(home: const LoginScreen()));
    final stateForTime = tester.state<LoginScreenState>(find.byType(LoginScreen));
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
      }
    ));
    expect(initialSignupResult, isNull);
    await mockAuth.signOut();

    // 2. authUser happy path (should find the player and call UserProvider.login)
    var authResult = await state.authUser(LoginData(name: 'test@example.com', password: 'password123'));
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
    await Player.createPlayer('Unclaimed', 'unclaimed', email: 'test_unclaimed@example.com', ownerId: 'unclaimed-db-id');
    await mockAuth.createUserWithEmailAndPassword(email: 'test_unclaimed@example.com', password: 'password123');
    await mockAuth.signOut();
    var authClaimResult = await state.authUser(LoginData(name: 'test_unclaimed@example.com', password: 'password123'));
    expect(authClaimResult, isNull);

    // authUser errors (FirebaseAuthException)
    final throwingAuth = ThrowingFirebaseAuth();
    userProvider.setAuthInstanceForTesting(throwingAuth);
    var errorResult = await state.authUser(LoginData(name: 'unknown@example.com', password: '123'));
    expect(errorResult, equals('Simulated Auth Exception'));

    final nullMessageThrowingAuth = NullMessageThrowingFirebaseAuth();
    userProvider.setAuthInstanceForTesting(nullMessageThrowingAuth);
    var nullErrorResult = await state.authUser(LoginData(name: 'unknown@example.com', password: '123'));
    expect(nullErrorResult, equals('An error occurred during login.'));

    final genericThrowingAuth = GenericThrowingFirebaseAuth();
    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var genericErrorResult = await state.authUser(LoginData(name: 'unknown@example.com', password: '123'));
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
      }
    ));
    expect(signupResult, isNull);
    
    // signupUser claim existing
    await Player.createPlayer('Existing', 'exist', email: 'existing@example.com', id: 'existing-id');
    var signupResultExisting = await state.signupUser(SignupData.fromSignupForm(
      name: 'existing@example.com',
      password: 'password123',
      additionalSignupData: {
        'playerName': 'Existing',
        'nickname': 'exist',
      }
    ));
    expect(signupResultExisting, isNotNull);

    // signupUser errors
    userProvider.setAuthInstanceForTesting(throwingAuth);
    var signupError = await state.signupUser(SignupData.fromSignupForm(
      name: 'error@example.com',
      password: 'password123',
      additionalSignupData: {'playerName': 'E', 'nickname': 'e'}
    ));
    expect(signupError, equals('Simulated Auth Exception'));

    userProvider.setAuthInstanceForTesting(nullMessageThrowingAuth);
    var nullSignupError = await state.signupUser(SignupData.fromSignupForm(
      name: 'error@example.com',
      password: 'password123',
      additionalSignupData: {'playerName': 'E', 'nickname': 'e'}
    ));
    expect(nullSignupError, equals('An error occurred during registration.'));

    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var genericSignupError = await state.signupUser(SignupData.fromSignupForm(
      name: 'error@example.com',
      password: 'password123',
      additionalSignupData: {'playerName': 'E', 'nickname': 'e'}
    ));
    expect(genericSignupError, equals('An error occurred during user registration.'));

    userProvider.setAuthInstanceForTesting(mockAuth);

    // recoverPassword
    var recoverResultFuture = state.recoverPassword('test@example.com');
    await tester.pump(const Duration(seconds: 5));
    var recoverResult = await recoverResultFuture;
    expect(recoverResult, isNull);
    
    // handleSocialLogin
    // Happy path (creates new user successfully)
    var socialResultFuture = state.handleSocialLogin('social_happy@example.com', 'Happy Social', 'social_happy@example.com');
    await tester.pump(const Duration(milliseconds: 200));
    var socialResult = await socialResultFuture;
    expect(socialResult, isNull);

    // Email already in use (falls back to sign in)
    final alreadyInUseAuth = AlreadyInUseFirebaseAuth(mockAuth);
    userProvider.setAuthInstanceForTesting(alreadyInUseAuth);
    var socialResultExistingFuture = state.handleSocialLogin('social_happy@example.com', 'Happy Social', 'social_happy@example.com');
    await tester.pump(const Duration(milliseconds: 200));
    var socialResultExisting = await socialResultExistingFuture;
    expect(socialResultExisting, isNull);
    userProvider.setAuthInstanceForTesting(mockAuth);

    // Generic Exception during sign-in
    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var socialErrorFuture = state.handleSocialLogin('social_error@example.com', 'Error Social', 'social_error@example.com');
    await tester.pump(const Duration(milliseconds: 200));
    var socialError = await socialErrorFuture;
    expect(socialError, contains('Sign-In failed:'));
    userProvider.setAuthInstanceForTesting(mockAuth);

    // handleGoogleLogin
    // Happy path (with mock credential)
    final googleCredential = GoogleAuthProvider.credential(idToken: 'mock-id-token', accessToken: 'mock-access-token');
    await tester.pumpWidget(MaterialApp(home: LoginScreen(mockGoogleCredential: googleCredential)));
    await tester.pump();
    
    // Create a known player in the db
    await fakeFirestore.collection('players').doc('google-uid').set({
      'player_name': 'Google User',
      'owner_id': 'google-uid',
      'email': 'google@example.com'
    });
    
    final googleHappyAuth = GoogleHappyFirebaseAuth();
    userProvider.setAuthInstanceForTesting(googleHappyAuth);
    final googleState = tester.state<LoginScreenState>(find.byType(LoginScreen));
    var googleResult = await googleState.handleGoogleLogin();
    expect(googleResult, isNull);

    // Error path (with mock credential but FirebaseAuth throws)
    userProvider.setAuthInstanceForTesting(genericThrowingAuth);
    var googleErrorResult = await googleState.handleGoogleLogin();
    expect(googleErrorResult, equals('Google Sign-In failed.'));
    userProvider.setAuthInstanceForTesting(mockAuth);
  });
}

class ThrowingFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    throw FirebaseAuthException(code: 'error', message: 'Simulated Auth Exception');
  }
  @override
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) {
    throw FirebaseAuthException(code: 'error', message: 'Simulated Auth Exception');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class NullMessageThrowingFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    throw FirebaseAuthException(code: 'error', message: null);
  }
  @override
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) {
    throw FirebaseAuthException(code: 'error', message: null);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GenericThrowingFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    throw Exception('Simulated Generic Exception');
  }
  @override
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) {
    throw Exception('Simulated Generic Exception');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CustomUser implements User {
  @override
  final String uid = 'google-uid';
  @override
  final String? email = 'google@example.com';
  @override
  final bool emailVerified = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CustomUserCredential implements UserCredential {
  @override
  final User? user = CustomUser();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GoogleHappyFirebaseAuth implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return CustomUserCredential();
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AlreadyInUseFirebaseAuth implements FirebaseAuth {
  final FirebaseAuth delegate;
  AlreadyInUseFirebaseAuth(this.delegate);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) {
    throw FirebaseAuthException(code: 'email-already-exists');
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    return delegate.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

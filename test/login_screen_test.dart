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

  Widget createLoginScreen() {
    return MaterialApp(
      home: const LoginScreen(),
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

  testWidgets('Social login simulation flows - Google Sign-In with new user',
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

    // Find the Google login button and tap it
    final googleButton = findIconByCodePoint(FontAwesomeIcons.google.codePoint);
    expect(googleButton, findsOneWidget);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);

    // Pump to allow the async _simulateSocialLogin and auth state changes stream to run
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // The user should now be logged in!
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'google_user@example.com');

    // Final pumps to clear any remaining timers
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
      'Social login simulation flows - Google Sign-In with pre-existing Auth user',
      (tester) async {
    // Pre-create the user in MockFirebaseAuth
    await mockAuth.createUserWithEmailAndPassword(
      email: 'google_user@example.com',
      password: 'mock_social_password_123',
    );
    await mockAuth
        .signOut(); // Ensure user starts logged out so the login screen is displayed

    final userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
    await userProvider.initialize();

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Force the 1-second Future.delayed to fire and complete the intro animation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Find the Google login button and tap it
    final googleButton = findIconByCodePoint(FontAwesomeIcons.google.codePoint);
    expect(googleButton, findsOneWidget);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // The user should now be logged in!
    expect(userProvider.loggedInUser, isNotNull);
    expect(userProvider.loggedInUser!.email, 'google_user@example.com');

    // Final pumps to clear any remaining timers
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
}

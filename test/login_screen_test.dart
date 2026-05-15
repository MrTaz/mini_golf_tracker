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

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    mockAuth = MockFirebaseAuth();
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
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Home Page')));
        }
        return null;
      },
    );
  }

  testWidgets('LoginScreen shows login form when not logged in', (tester) async {
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
    expect(find.byIcon(FontAwesomeIcons.google), findsOneWidget);
    expect(find.byIcon(FontAwesomeIcons.facebookF), findsOneWidget);
    expect(find.byIcon(FontAwesomeIcons.snapchat), findsOneWidget);
    expect(find.byIcon(FontAwesomeIcons.instagram), findsOneWidget);

    // Add extra pump to clear timers from animations
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('LoginScreen shows Account Details when logged in', (tester) async {
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
}

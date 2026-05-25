import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().setAuthInstanceForTesting(mockAuth);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Auth E2E Test: Test Account Bypass Flow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Create an UNCLAIMED player in DB for test@example.com
    await Player.createPlayer('Test User', 'Tester', email: 'test@example.com', ownerId: 'some-other-person-id');

    // Pre-create user in mock auth so signing in doesn't fail
    await mockAuth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password123');
    await mockAuth.signOut();

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/': (context) => const Scaffold(body: Text('DashboardScreen')),
        },
      )
    );
    await tester.pumpAndSettle();
    
    // flutter_login hit-test bug/animation bypass
    int pumps = 0;
    while(find.byType(TextFormField).evaluate().isEmpty && pumps < 100) {
      await tester.pump(const Duration(milliseconds: 100));
      pumps++;
    }

    if (find.byType(TextFormField).evaluate().isEmpty) {
      debugPrint("No TextFormField found! Widget tree:");
      debugDumpApp();
    }

    final emailField = find.byType(TextFormField).at(0);
    final passwordField = find.byType(TextFormField).at(1);

    await tester.enterText(emailField, 'test@example.com');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(passwordField, 'password123');
    await tester.pump(const Duration(milliseconds: 100));

    // Find Login button
    final loginButton = find.text('LOGIN');
    await tester.tap(loginButton);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Verify it routes to the dashboard screen
    // Wait for the login animation and navigation to complete
    int postPumps = 0;
    while(find.text('DashboardScreen').evaluate().isEmpty && postPumps < 50) {
      await tester.pump(const Duration(milliseconds: 100));
      postPumps++;
    }

    expect(find.text('DashboardScreen'), findsOneWidget);
    
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

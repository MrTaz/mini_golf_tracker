import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/home_screen.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_create_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mini_golf_tracker/main.dart';
import '../../../../test_helper.dart';

void main() {
  setUp(() {
    UserProvider().setAuthInstanceForTesting(MockFirebaseAuth());
    UserProvider().loggedInUser = null;
    MainScaffold.skipPrecacheForTesting = true;
  });

  tearDown(() {
    UserProvider().resetForTesting();
  });

  testWidgets('HomeScreen renders logged out view',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Welcome, Guest"), findsOneWidget);
    expect(find.text("User Login"), findsOneWidget);
    expect(find.text("Create a New Game"), findsOneWidget);

    // Tap User Login navigates to LoginScreen
    await tester.tap(find.text("User Login"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('HomeScreen renders logged in view without email',
      (WidgetTester tester) async {
    UserProvider().loggedInUser = Player(
      id: 'p1',
      playerName: 'Test Player',
      nickname: 'Tester',
      ownerId: 'p1',
      totalScore: 0,
    );
    // trigger notifyListeners somehow, but since we recreate the widget it will pick up the new state
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Welcome, Tester"), findsOneWidget);
    expect(find.text("Logout"), findsOneWidget);

    // Test Create Game tap
    await tester.tap(find.text("Create a New Game"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(GameCreateScreen), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('HomeScreen renders logged in view with email',
      (WidgetTester tester) async {
    UserProvider().loggedInUser = Player(
      id: 'p1',
      playerName: 'Test Player',
      nickname: 'Tester',
      ownerId: 'p1',
      totalScore: 0,
      email: 'tester@example.com',
    );
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Welcome, Tester"), findsOneWidget);

    // Tap Logout
    await tester.tap(find.text("Logout"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 5));
  });
}

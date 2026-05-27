import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(MockFirebaseAuth());
    Player.players = [
      Player(
        id: 'guest',
        playerName: 'Guest Scorekeeper',
        nickname: 'Guest',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ];
    await Player.saveLocalGuestPlayers();
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
  });

  testWidgets('guest scorekeeper PII banner routes to login', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayersScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guest Scorekeeper'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nickname'), findsOneWidget);
    expect(
      find.text(
        'Log in or sign up to set your real name, email, and phone number!',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text(
        'Log in or sign up to set your real name, email, and phone number!',
      ),
      findsOneWidget,
    );
  });
}

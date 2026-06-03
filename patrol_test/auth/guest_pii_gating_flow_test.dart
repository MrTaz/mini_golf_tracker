// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  patrolTest('guest scorekeeper PII banner routes to login', ($) async {
    await $.pumpWidgetAndSettle(
      const MaterialApp(home: PlayersScreen()),
    );

    expect($('Guest Scorekeeper'), findsOneWidget);

    await $(Icons.edit).tap();
    await $.pumpAndSettle();

    expect($(find.widgetWithText(TextFormField, 'Nickname')), findsOneWidget);
    expect(
      $('Log in or sign up to set your real name, email, and phone number!'),
      findsOneWidget,
    );

    await $(Icons.lock_outline).tap();
    await $.pumpAndSettle();
    await $.pump(const Duration(seconds: 1));

    expect($(LoginScreen), findsOneWidget);
    expect(
      $('Log in or sign up to set your real name, email, and phone number!'),
      findsOneWidget,
    );
  });
}

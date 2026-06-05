// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/database_connection.dart';
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
    Player.players = [];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
  });

  patrolTest(
    'create a new Quick-Play player using only a nickname and save successfully',
    ($) async {
      // 1. Log in an authenticated user so that mandatory email/phone validation would ordinarily trigger.
      final loggedInUser = Player(
        id: 'auth-user-1',
        playerName: 'Auth User One',
        nickname: 'AuthOne',
        ownerId: 'auth-user-1',
        totalScore: 0,
        email: 'auth1@example.com',
      );
      await UserProvider().login(loggedInUser);

      // 2. Open PlayersScreen.
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: PlayersScreen(creatingGame: true),
        ),
      );

      // 3. Tap the add player button.
      await $(Icons.person_add).tap();
      await $.pumpAndSettle();

      // 4. Fill in only Nickname, leaving Player Name, Email, and Phone blank.
      await $(find.widgetWithText(TextFormField, 'Nickname')).enterText('QuickNick');
      await $.pumpAndSettle();


      // 6. Tap "Add Player" button to save.
      await $('Add Player').tap();
      await $.pumpAndSettle();

      // 7. Verify validation succeeded, form closed, and player appears in the list.
      expect($('Missing contact information'), findsNothing);
      expect($('Missing required fields'), findsNothing);
      expect($('QuickNick'), findsWidgets);
    },
  );
}

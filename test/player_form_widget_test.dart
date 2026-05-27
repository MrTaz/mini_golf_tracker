import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_form_widget.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
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

  testWidgets('standard form omits status field and edit header id',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'player-1',
              playerName: 'Ava Guest',
              nickname: 'Ava',
              ownerId: 'guest',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    expect(find.text('Edit Player Attributes'), findsOneWidget);
    expect(find.textContaining('player-1'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Status'), findsNothing);
    expect(
      tester.state<PlayerFormState>(find.byType(PlayerForm)).isEditing,
      isTrue,
    );
  });

  testWidgets('standard form required-field dialogs can be dismissed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'player-1',
              playerName: '',
              nickname: '',
              ownerId: 'guest',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Missing required fields'), findsOneWidget);
    expect(find.text("The Player's Name must be filled in."), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      'Ava Guest',
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Missing required fields'), findsOneWidget);
    expect(
      find.text("The Player's Nickname must be filled in."),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Missing required fields'), findsNothing);
  });

  testWidgets('duplicate dialog can be dismissed', (tester) async {
    Player.players = [
      Player(
        id: 'existing',
        playerName: 'Ava Guest',
        nickname: 'Ava',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'new-player',
              playerName: 'Ava Guest',
              nickname: 'Ava',
              ownerId: 'guest',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate Player'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Duplicate Player'), findsNothing);
  });

  testWidgets('guest scorekeeper only sees nickname and login banner',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'guest',
              playerName: 'Guest Scorekeeper',
              nickname: 'Guest',
              ownerId: 'guest',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Nickname'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Player Name'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Phone Number'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(
      find.text(
        'Log in or sign up to set your real name, email, and phone number!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('guest scorekeeper banner routes to login screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'guest',
              playerName: 'Guest Scorekeeper',
              nickname: 'Guest',
              ownerId: 'guest',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
          ),
        ),
      ),
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

  testWidgets('guest scorekeeper saves nickname as required player name',
      (tester) async {
    final guest = Player(
      id: 'guest',
      playerName: 'Guest Scorekeeper',
      nickname: 'Guest',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: guest,
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nickname'),
      'Scorekeeper',
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(guest.nickname, 'Scorekeeper');
    expect(guest.playerName, 'Scorekeeper');
  });
}

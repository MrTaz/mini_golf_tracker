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

  testWidgets(
      'guest scorekeeper saves editable nickname with Guest player name',
      (tester) async {
    final guest = Player(
      id: 'guest',
      playerName: 'Guest',
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
    expect(guest.playerName, 'Guest');
  });

  testWidgets('privacy toggles render and save for profile owner',
      (tester) async {
    final player = Player(
      id: 'player-1',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'player-1',
      totalScore: 0,
      email: 'ava@example.com',
    );
    await UserProvider().login(player);
    await DatabaseConnection.client
        .collection('players')
        .doc(player.id)
        .set(player.toJson());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: player,
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    expect(find.text('Privacy Settings'), findsOneWidget);
    expect(find.text('Show Real Name'), findsOneWidget);
    expect(find.text('Show Email'), findsOneWidget);
    expect(find.text('Show Phone Number'), findsOneWidget);

    await tester.tap(find.text('Show Real Name'));
    await tester.tap(find.text('Show Email'));
    await tester.tap(find.text('Show Phone Number'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(player.shareName, isFalse);
    expect(player.shareEmail, isFalse);
    expect(player.sharePhone, isFalse);
  });

  testWidgets('privacy toggles do not render for friend profile',
      (tester) async {
    await UserProvider().login(Player(
      id: 'owner-1',
      playerName: 'Owner',
      nickname: 'Owner',
      ownerId: 'owner-1',
      totalScore: 0,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'friend-1',
              playerName: 'Friend Guest',
              nickname: 'Friend',
              ownerId: 'owner-1',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    expect(find.text('Privacy Settings'), findsNothing);
    expect(find.text('Show Real Name'), findsNothing);
    expect(find.text('Show Email'), findsNothing);
    expect(find.text('Show Phone Number'), findsNothing);
  });

  testWidgets('non-quick-play form requires email or phone number',
      (tester) async {
    final loggedInUser = Player(
      id: 'owner-1',
      playerName: 'Owner Player',
      nickname: 'Owner',
      ownerId: 'owner-1',
      totalScore: 0,
    );
    await UserProvider().login(loggedInUser);

    final player = Player(
      id: 'player-1',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'guest',
      totalScore: 0,
      isQuickPlay: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: player,
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
            isQuickPlay: false,
          ),
        ),
      ),
    );

    // Clear email and phone number
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      '',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '',
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Missing contact information'), findsOneWidget);
    expect(
      find.text('Please enter either an email address or a phone number for non-Quick-Play players.'),
      findsOneWidget,
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Missing contact information'), findsNothing);
  });

  testWidgets('quick-play form bypasses email and phone number validation',
      (tester) async {
    final player = Player(
      id: 'player-1',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'guest',
      totalScore: 0,
      isQuickPlay: true,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: player,
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () => saved = true,
            isQuickPlay: true,
          ),
        ),
      ),
    );

    // Clear player name, email, and phone number
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      '',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      '',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '',
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Missing contact information'), findsNothing);
    expect(saved, isTrue);
  });

  testWidgets('quick-play switch toggles state', (tester) async {
    final player = Player(
      id: 'player-1',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'guest',
      totalScore: 0,
      isQuickPlay: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: player,
            allowEditing: true,
            editingOrAdding: 'Edit',
            onSaveChanges: () {},
            isQuickPlay: false,
          ),
        ),
      ),
    );

    final switchFinder = find.byKey(const Key('quick_play_switch'));
    expect(switchFinder, findsOneWidget);

    // Verify it is false initially
    var switchWidget = tester.widget<SwitchListTile>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Tap it to toggle
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    switchWidget = tester.widget<SwitchListTile>(switchFinder);
    expect(switchWidget.value, isTrue);
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/players/presentation/widgets/player_form_widget.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
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
              email: 'test@example.com',
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

  testWidgets('quick-play form bypasses email and phone number validation',
      (tester) async {
    final player = Player(
      id: 'player-1',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'guest',
      totalScore: 0,
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

  testWidgets(
      'quick-play form copies nickname to playerName when playerName is blank',
      (tester) async {
    final player = Player(
      id: 'player-1',
      playerName: '',
      nickname: 'AvaNick',
      ownerId: 'guest',
      totalScore: 0,
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
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(player.playerName, 'AvaNick');
    expect(player.isQuickPlay, isTrue);
  });

  testWidgets('detects email collision and blocks save', (tester) async {
    final existingPlayer = Player(
      id: 'existing-id',
      playerName: 'Existing Player',
      nickname: 'Existing',
      ownerId: 'some-owner',
      totalScore: 0,
      email: 'collision@example.com',
      normalizedEmail: 'collision@example.com',
    );
    await DatabaseConnection.client
        .collection('players')
        .doc(existingPlayer.id)
        .set(existingPlayer.toJson());

    await DatabaseConnection.client
        .collection('player_contacts')
        .doc('email_collision@example.com')
        .set({
      'kind': 'email',
      'normalized_value': 'collision@example.com',
      'player_id': 'existing-id',
      'created_by_uid': 'some-owner',
    });

    final newPlayer = Player(
      id: 'new-player-id',
      playerName: 'New Player',
      nickname: 'New',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: newPlayer,
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'collision@example.com',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    expect(
      find.text('This email/phone number is already in use by another player.'),
      findsOneWidget,
    );
    expect(saved, isFalse);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Contact Collision'), findsNothing);

    final doc = await DatabaseConnection.client
        .collection('players')
        .doc('new-player-id')
        .get();
    expect(doc.exists, isFalse);
  });

  testWidgets('detects phone collision and blocks save', (tester) async {
    final existingPlayer = Player(
      id: 'existing-id',
      playerName: 'Existing Player',
      nickname: 'Existing',
      ownerId: 'some-owner',
      totalScore: 0,
      phoneNumber: '+1234567890',
      normalizedPhoneNumber: '+1234567890',
    );
    await DatabaseConnection.client
        .collection('players')
        .doc(existingPlayer.id)
        .set(existingPlayer.toJson());

    await DatabaseConnection.client
        .collection('player_contacts')
        .doc('phone_+1234567890')
        .set({
      'kind': 'phone',
      'normalized_value': '+1234567890',
      'player_id': 'existing-id',
      'created_by_uid': 'some-owner',
    });

    final newPlayer = Player(
      id: 'new-player-id',
      playerName: 'New Player',
      nickname: 'New',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: newPlayer,
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '+1234567890',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    expect(
      find.text('This email/phone number is already in use by another player.'),
      findsOneWidget,
    );
    expect(saved, isFalse);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final doc = await DatabaseConnection.client
        .collection('players')
        .doc('new-player-id')
        .get();
    expect(doc.exists, isFalse);
  });

  testWidgets('detects local list contact collision and blocks save',
      (tester) async {
    Player.players = [
      Player(
        id: 'local-friend-id',
        playerName: 'Local Friend',
        nickname: 'Local',
        ownerId: 'guest',
        totalScore: 0,
        email: 'local@example.com',
        normalizedEmail: 'local@example.com',
      ),
    ];

    final newPlayer = Player(
      id: 'new-player-id',
      playerName: 'New Player',
      nickname: 'New',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: newPlayer,
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'local@example.com',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    expect(saved, isFalse);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('successful save writes normalized contact strings',
      (tester) async {
    final owner = Player(
      id: 'owner-id',
      playerName: 'Owner',
      nickname: 'Owner',
      ownerId: 'owner-id',
      totalScore: 0,
    );
    await UserProvider().login(owner);

    final newPlayer = Player(
      id: 'new-player-id',
      playerName: 'New Player',
      nickname: 'New',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: newPlayer,
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      ' SUCCESS@EXAMPLE.COM ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      ' +1 (234) 567-8901 ',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);

    expect(newPlayer.email, 'success@example.com');
    expect(newPlayer.phoneNumber, '+12345678901');
    expect(newPlayer.normalizedEmail, 'success@example.com');
    expect(newPlayer.normalizedPhoneNumber, '+12345678901');

    final snapshot = await DatabaseConnection.client
        .collection('players')
        .where('normalized_email', isEqualTo: 'success@example.com')
        .get();
    expect(snapshot.docs.isNotEmpty, isTrue);
    final doc = snapshot.docs.first;
    expect(doc.data()['email'], 'success@example.com');
    expect(doc.data()['phone_number'], '+12345678901');
    expect(doc.data()['normalized_email'], 'success@example.com');
    expect(doc.data()['normalized_phone_number'], '+12345678901');
  });

  testWidgets('detects local phone contact collision and blocks save',
      (tester) async {
    Player.players = [
      Player(
        id: 'local-friend-id',
        playerName: 'Local Friend',
        nickname: 'Local',
        ownerId: 'guest',
        totalScore: 0,
        phoneNumber: '+1234567890',
        normalizedPhoneNumber: '+1234567890',
      ),
    ];

    final newPlayer = Player(
      id: 'new-player-id',
      playerName: 'New Player',
      nickname: 'New',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: newPlayer,
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '+1234567890',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    expect(saved, isFalse);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'handles firestore exception during db collision check gracefully',
      (tester) async {
    DatabaseConnection.setFirestoreInstanceForTesting(ThrowingFirestore());

    final newPlayer = Player(
      id: 'new-player-id',
      playerName: 'New Player',
      nickname: 'New',
      ownerId: 'guest',
      totalScore: 0,
    );
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: newPlayer,
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () => saved = true,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'error@example.com',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    // Since firestore throws, collision check fails but it doesn't crash the app, and proceed to save.
    expect(saved, isTrue);
  });

  testWidgets(
      'saves and overwrites existing local guest player in saveChanges branch',
      (tester) async {
    final guestPlayer = Player(
      id: 'existing-guest-id',
      playerName: 'Old Guest Name',
      nickname: 'Old Guest',
      ownerId: 'guest',
      totalScore: 0,
    );
    Player.players = [guestPlayer];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'existing-guest-id',
              playerName: 'New Guest Name',
              nickname: 'New Guest',
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

    // Call saveChanges directly to bypass checkDuplicate and force entering the overwriting branch
    final state = tester.state<PlayerFormState>(find.byType(PlayerForm));
    await state.saveChanges();
    await tester.pumpAndSettle();

    expect(Player.players, hasLength(1));
    expect(Player.players.single.playerName, 'New Guest Name');
  });
}

class ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'players') {
      final stack = StackTrace.current.toString();
      if (stack.contains('checkDuplicate') &&
          !stack.contains('saveChanges') &&
          !stack.contains('resolveGuestPlayer') &&
          !stack.contains('addPlayerFriend')) {
        throw FirebaseException(
            plugin: 'firestore', message: 'Simulated DB Error');
      }
    }
    return super.collection(path);
  }
}

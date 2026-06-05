import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_form_widget.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    Player.players = [];
  });

  tearDown(() {
    Player.players = [];
  });

  testWidgets('guest can add and view a player from player selection',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayersScreen(creatingGame: true)),
    );

    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      'Taylor Guest',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nickname'),
      'Taylor',
    );

    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(Player.players, hasLength(1));
    expect(Player.players.single.ownerId, 'guest');
    expect(find.text('Taylor'), findsOneWidget);
    expect(find.text('Taylor Guest'), findsOneWidget);
  });

  testWidgets('guest players persist locally and reload in a new picker',
      (tester) async {
    final player = Player(
      id: 'guest-1',
      playerName: 'Morgan Guest',
      nickname: 'Morgan',
      ownerId: 'guest',
      totalScore: 0,
    );
    Player.players = [player];
    await Player.saveLocalGuestPlayers();
    Player.players = [];

    await tester.pumpWidget(
      const MaterialApp(home: PlayersScreen(creatingGame: true)),
    );
    await tester.pumpAndSettle();

    expect(Player.players.single.id, 'guest-1');
    expect(find.text('Morgan'), findsOneWidget);
  });

  testWidgets('guest uses existing contact-backed player nickname',
      (tester) async {
    await DatabaseConnection.client
        .collection('players')
        .doc('known-player')
        .set({
      'player_name': 'Known Player',
      'nickname': 'Canonical',
      'owner_id': 'creator-1',
      'email': 'known@example.com',
      'total_score': 0,
    });

    await tester.pumpWidget(
      const MaterialApp(home: PlayersScreen(creatingGame: true)),
    );
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      'Entered Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nickname'),
      'Entered Nick',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'known@example.com',
    );
    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'guest refreshes existing local player with canonical contact data',
      (tester) async {
    Player.players = [
      Player(
        id: 'known-player',
        playerName: 'Old Local Name',
        nickname: 'Old Local',
        ownerId: 'guest',
        totalScore: 0,
        email: 'known@example.com',
      ),
    ];
    await DatabaseConnection.client
        .collection('players')
        .doc('known-player')
        .set({
      'player_name': 'Known Player',
      'nickname': 'Canonical',
      'owner_id': 'creator-1',
      'email': 'known@example.com',
      'total_score': 0,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'temp-player',
              playerName: '',
              nickname: '',
              ownerId: '',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      'Entered Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nickname'),
      'Entered Nick',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'known@example.com',
    );
    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('logged in user add form uses canonical contact-backed player',
      (tester) async {
    final owner = Player(
      id: 'owner-1',
      playerName: 'Owner',
      nickname: 'Owner',
      ownerId: 'owner-1',
      totalScore: 0,
      email: 'owner@example.com',
    );
    UserProvider().loggedInUser = owner;
    await DatabaseConnection.client
        .collection('players')
        .doc('known-player')
        .set({
      'player_name': 'Known Player',
      'nickname': 'Canonical',
      'owner_id': 'creator-1',
      'email': 'known@example.com',
      'total_score': 0,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'temp-player',
              playerName: '',
              nickname: '',
              ownerId: '',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      'Entered Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nickname'),
      'Entered Nick',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'known@example.com',
    );
    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Collision'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('guest picker restores previously selected local players',
      (tester) async {
    final player = Player(
      id: 'guest-1',
      playerName: 'Morgan Guest',
      nickname: 'Morgan',
      ownerId: 'guest',
      totalScore: 0,
    );
    Player.players = [player];

    await tester.pumpWidget(
      MaterialApp(
        home: PlayersScreen(
          creatingGame: true,
          currentlySelectedPlayers: [
            PlayerGameInfo(
              playerId: player.id,
              gameId: 'game-1',
              scores: const [],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(find.byType(Switch).last);
    expect(switchWidget.value, isTrue);
    expect(find.text('Morgan'), findsOneWidget);
  });

  testWidgets('guest duplicate player is rejected', (tester) async {
    final existingPlayer = Player(
      id: 'guest-1',
      playerName: 'Taylor Guest',
      nickname: 'Taylor',
      ownerId: 'guest',
      totalScore: 0,
    );
    Player.players = [existingPlayer];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerForm(
            player: Player(
              id: 'guest-2',
              playerName: '',
              nickname: '',
              ownerId: '',
              totalScore: 0,
            ),
            allowEditing: true,
            editingOrAdding: 'Add',
            onSaveChanges: () {},
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Player Name'),
      'Taylor Guest',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nickname'),
      'Taylor',
    );
    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate Player'), findsOneWidget);
    expect(Player.players, hasLength(1));
  });
}

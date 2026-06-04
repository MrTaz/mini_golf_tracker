import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/players_list_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mini_golf_tracker/database_connection.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    UserProvider().resetForTesting();
    UserProvider().setAuthInstanceForTesting(mockAuth);
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
  });

  Player testPlayer() {
    return Player(
      id: 'p1',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'guest',
      totalScore: 7,
      email: 'ava@example.com',
      phoneNumber: '5551234567',
    );
  }

  testWidgets(
      'PlayerListItem renders with listOrderNumber and checks suffix logic',
      (tester) async {
    // position % 10 == 1
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 1))));
    expect(find.text('1st'), findsOneWidget);

    // position % 10 == 2
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 2))));
    expect(find.text('2nd'), findsOneWidget);

    // position % 10 == 3
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 3))));
    expect(find.text('3rd'), findsOneWidget);

    // position % 10 == 4
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 4))));
    expect(find.text('4th'), findsOneWidget);

    // position % 100 == 11
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 11))));
    expect(find.text('11th'), findsOneWidget);

    // position % 100 == 12
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 12))));
    expect(find.text('12th'), findsOneWidget);

    // position % 100 == 13
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(player: testPlayer(), listOrderNumber: 13))));
    expect(find.text('13th'), findsOneWidget);
  });

  testWidgets('PlayerListItem toggles dropdown and edit icon state',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PlayerListItem(player: testPlayer()))));

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);

    // Tap to open
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsWidgets);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNothing);

    // Tap to close instead of Save, because unauthenticated users don't see the Save button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsNothing);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('PlayerListItem hides PII until read-only expansion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer()))),
    );

    expect(find.text('ava@example.com'), findsNothing);
    expect(find.text('5551234567'), findsNothing);
    expect(find.text('7'), findsNothing);

    await tester.tap(find.text('Ava Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Total Score'), findsOneWidget);
    expect(find.text('ava@example.com'), findsOneWidget);
    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await tester.tap(find.text('Ava Guest'));
    await tester.pumpAndSettle();

    expect(find.text('ava@example.com'), findsNothing);
    expect(find.text('5551234567'), findsNothing);
  });

  testWidgets('PlayerListItem masks email hidden by non-owner', (tester) async {
    final player = testPlayer()..shareEmail = false;
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PlayerListItem(player: player))),
    );

    await tester.tap(find.text('Ava Guest'));
    await tester.pumpAndSettle();

    expect(find.text('ava@example.com'), findsNothing);
    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('Hidden by user'), findsOneWidget);
  });

  testWidgets('PlayerListItem masks phone and name hidden by non-owner',
      (tester) async {
    final player = testPlayer()
      ..shareName = false
      ..sharePhone = false;
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PlayerListItem(player: player))),
    );

    expect(find.text('Ava Guest'), findsNothing);
    expect(find.text('Ava'), findsWidgets);

    await tester.tap(find.text('Ava').first);
    await tester.pumpAndSettle();

    expect(find.text('5551234567'), findsNothing);
    expect(find.text('Hidden by user'), findsOneWidget);
  });

  testWidgets('PlayerListItem reveals hidden fields to owner', (tester) async {
    final player = Player(
      id: 'owner123',
      playerName: 'Ava Guest',
      nickname: 'Ava',
      ownerId: 'owner123',
      totalScore: 7,
      email: 'ava@example.com',
      phoneNumber: '5551234567',
      shareName: false,
      shareEmail: false,
      sharePhone: false,
    );
    await UserProvider().login(player);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PlayerListItem(player: player))),
    );

    expect(find.text('Ava Guest'), findsOneWidget);

    await tester.tap(find.text('Ava Guest'));
    await tester.pumpAndSettle();

    expect(find.text('ava@example.com'), findsOneWidget);
    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('Hidden by user'), findsNothing);
  });

  testWidgets('PlayerListItem selection tap and switch tap', (tester) async {
    bool selected = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(
      player: testPlayer(),
      creatingGame: true,
      onPlayerSelected: (p) => selected = true,
      isSelected: false,
    ))));

    // Tap ListTile to trigger isSelected = !isSelected
    await tester.tap(find.text('Ava Guest'));
    await tester.pumpAndSettle();

    // Tap switch to trigger isSelected = value!
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(selected, true);
  });

  testWidgets(
      'PlayerListItem selection tap and switch tap calls onPlayerSelected',
      (tester) async {
    int selectedCount = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlayerListItem(
      player: testPlayer(),
      creatingGame: true,
      onPlayerSelected: (p) => selectedCount++,
      isSelected: false,
    ))));

    // Tap ListTile (should call onPlayerSelected)
    await tester.tap(find.text('Ava Guest'));
    await tester.pumpAndSettle();
    expect(selectedCount, 1);

    // Tap switch (should call onPlayerSelected)
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(selectedCount, 2);
  });

  testWidgets('PlayerListItem didUpdateWidget state sync', (tester) async {
    await tester.pumpWidget(const TestWrapper());
    final state =
        tester.state<PlayerListItemState>(find.byType(PlayerListItem));
    expect(state.isSelected, false);

    // Update parent state via public helper to avoid analyzer warnings
    final wrapperState =
        tester.state<TestWrapperState>(find.byType(TestWrapper));
    wrapperState.updateSelected(true);
    await tester.pumpAndSettle();

    expect(state.isSelected, true);
  });

  testWidgets('PlayerListItem onRemove works', (tester) async {
    bool removed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerListItem(
          player: testPlayer(),
          onRemove: () => removed = true,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.remove_circle));
    await tester.pumpAndSettle();
    expect(removed, true);
  });

  testWidgets(
      'PlayerListItem save edited changes closes dropdown for authenticated owner',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final owner = Player(
      id: 'owner123',
      playerName: 'Owner Player',
      nickname: 'Owner',
      ownerId: 'owner123',
      totalScore: 0,
      isQuickPlay: true,
    );
    await UserProvider().login(owner);

    // Pre-create player in fake Firestore so update() doesn't throw not-found
    await fakeFirestore
        .collection('players')
        .doc('owner123')
        .set(owner.toJson());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerListItem(
          player: owner,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap to open edit dropdown
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsWidgets);

    // Tap save button (it's inside PlayerForm)
    final saveButton = find.text('Save Changes');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Should close dropdown
    expect(find.byType(Divider), findsNothing);
  });
}

class TestWrapper extends StatefulWidget {
  const TestWrapper({super.key});
  @override
  TestWrapperState createState() => TestWrapperState();
}

class TestWrapperState extends State<TestWrapper> {
  bool isSelected = false;

  void updateSelected(bool val) {
    setState(() {
      isSelected = val;
    });
  }

  Player testPlayer() {
    return Player(
        id: 'p1',
        playerName: 'Ava Guest',
        nickname: 'Ava',
        ownerId: 'guest',
        totalScore: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PlayerListItem(
          player: testPlayer(),
          creatingGame: true,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

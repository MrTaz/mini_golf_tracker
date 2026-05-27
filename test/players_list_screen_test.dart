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
    return Player(id: 'p1', playerName: 'Ava Guest', nickname: 'Ava', ownerId: 'guest', totalScore: 0);
  }

  testWidgets('PlayerListItem renders with listOrderNumber and checks suffix logic', (tester) async {
    // position % 10 == 1
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 1))));
    expect(find.text('1st'), findsOneWidget);

    // position % 10 == 2
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 2))));
    expect(find.text('2nd'), findsOneWidget);

    // position % 10 == 3
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 3))));
    expect(find.text('3rd'), findsOneWidget);

    // position % 10 == 4
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 4))));
    expect(find.text('4th'), findsOneWidget);
    
    // position % 100 == 11
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 11))));
    expect(find.text('11th'), findsOneWidget);

    // position % 100 == 12
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 12))));
    expect(find.text('12th'), findsOneWidget);

    // position % 100 == 13
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer(), listOrderNumber: 13))));
    expect(find.text('13th'), findsOneWidget);
  });

  testWidgets('PlayerListItem toggles dropdown when edit icon is tapped', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(player: testPlayer()))));
    
    // Tap to open
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsWidgets);

    // Tap to close instead of Save, because unauthenticated users don't see the Save button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('PlayerListItem selection tap and switch tap', (tester) async {
    bool selected = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(
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

  testWidgets('PlayerListItem selection tap and switch tap calls onPlayerSelected', (tester) async {
    int selectedCount = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayerListItem(
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
    final state = tester.state<PlayerListItemState>(find.byType(PlayerListItem));
    expect(state.isSelected, false);

    // Update parent state via public helper to avoid analyzer warnings
    final wrapperState = tester.state<TestWrapperState>(find.byType(TestWrapper));
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

  testWidgets('PlayerListItem save edited changes closes dropdown for authenticated owner', (tester) async {
    final owner = Player(
      id: 'owner123',
      playerName: 'Owner Player',
      nickname: 'Owner',
      ownerId: 'owner123',
      totalScore: 0,
    );
    await UserProvider().login(owner);

    // Pre-create player in fake Firestore so update() doesn't throw not-found
    await fakeFirestore.collection('players').doc('owner123').set(owner.toJson());

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
    return Player(id: 'p1', playerName: 'Ava Guest', nickname: 'Ava', ownerId: 'guest', totalScore: 0);
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


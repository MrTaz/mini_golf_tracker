import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_details_screen.dart';

void main() {
  testWidgets('PlayerDetailsScreen renders correctly and allows editing', (WidgetTester tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Original Name',
      nickname: 'Original Nickname',
      ownerId: 'owner1',
      totalScore: 10,
      email: 'original@example.com',
      phoneNumber: '1234567890',
      status: 'active',
    );

    await tester.pumpWidget(MaterialApp(
      home: PlayerDetailsScreen(player: player),
    ));

    expect(find.text('Player Details'), findsOneWidget);
    expect(find.text('Original Name'), findsOneWidget);
    expect(find.text('Original Nickname'), findsOneWidget);
    expect(find.text('original@example.com'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    // Edit fields
    await tester.enterText(find.byType(TextFormField).at(0), 'New Name');
    await tester.enterText(find.byType(TextFormField).at(1), 'New Nickname');
    await tester.enterText(find.byType(TextFormField).at(2), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(3), '0987654321');
    await tester.enterText(find.byType(TextFormField).at(4), 'inactive');
    await tester.enterText(find.byType(TextFormField).at(5), '20');

    await tester.pumpAndSettle();

    expect(player.playerName, 'New Name');
    expect(player.nickname, 'New Nickname');
    expect(player.email, 'new@example.com');
    expect(player.phoneNumber, '0987654321');
    expect(player.status, 'inactive');
    expect(player.totalScore, 20);
  });
}

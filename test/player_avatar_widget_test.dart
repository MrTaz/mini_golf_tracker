import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/gravatar_image_view.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_avatar_widget.dart';

void main() {
  Widget buildAvatar(Player player) {
    return MaterialApp(
      home: Scaffold(
        body: PlayerAvatarWidget(player: player, radius: 24),
      ),
    );
  }

  testWidgets('uses asset fallback for players without email', (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'No Email',
      nickname: 'NE',
      ownerId: 'guest',
      totalScore: 0,
    );

    await tester.pumpWidget(buildAvatar(player));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('N'), findsNothing);
  });

  testWidgets('uses asset fallback for players with empty email',
      (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Empty Email',
      nickname: 'EE',
      ownerId: 'guest',
      totalScore: 0,
      email: '',
    );

    await tester.pumpWidget(buildAvatar(player));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('E'), findsNothing);
  });

  testWidgets('uses gravatar for players with email', (tester) async {
    final player = Player(
      id: 'p1',
      playerName: 'Email Player',
      nickname: 'EP',
      ownerId: 'guest',
      totalScore: 0,
      email: 'player@example.com',
    );

    await tester.pumpWidget(buildAvatar(player));

    expect(find.byType(GravatarImageView), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

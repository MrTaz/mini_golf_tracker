import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/past_games_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    SharedPreferences.setMockInitialValues({});
    UserProvider().resetForTesting();
    Player.players = [];
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
    Player.players = [];
  });

  testWidgets('PastGamesListView throws when not logged in', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PastGamesListView())));
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('PastGamesListView renders with games when logged in', (tester) async {
    final creator = Player(
      id: 'creator1',
      playerName: 'Jane',
      nickname: 'Jane',
      ownerId: 'creator1',
      totalScore: 0,
    );
    await UserProvider().login(creator);

    final game = Game(
      id: 'g1',
      name: 'Test Game',
      course: Course(id: 'c1', name: 'Pinecrest', numberOfHoles: 1, parStrokes: {1: 3}),
      players: [
        PlayerGameInfo(playerId: 'creator1', gameId: 'g1', scores: [2]),
      ],
      scheduledTime: DateTime(2026, 1, 1),
      startTime: DateTime(2026, 1, 1),
      completedTime: DateTime(2026, 1, 1),
      status: 'completed',
    );

    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    await Game.saveGameToDatabase(game, creator);

    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Column(children: [Expanded(child: PastGamesListView())]))));
    
    // Pump several times to let microtask and FutureBuilder complete
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Pinecrest'), findsOneWidget);
    expect(find.text('Winner: Jane'), findsOneWidget);
  });
}

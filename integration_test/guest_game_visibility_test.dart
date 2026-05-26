import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
  });

  test('guest-created cloud game is visible by registered participant id',
      () async {
    final registeredPlayer = PlayerGameInfo(
      playerId: 'registered-player-1',
      gameId: 'guest-cloud-game',
      scores: [3, 4, 5],
      totalScore: 12,
      playOrderPosition: 1,
      place: '1st',
    );
    final game = Game(
      id: 'guest-cloud-game',
      name: 'Guest Cloud Game',
      course: Course(
        id: 'course-1',
        name: 'Visibility Course',
        numberOfHoles: 3,
        parStrokes: {1: 3, 2: 4, 3: 5},
      ),
      players: [registeredPlayer],
      scheduledTime: DateTime(2026, 5, 25, 12),
      status: 'completed',
    );
    final guestCreator = Player(
      id: 'guest-scorekeeper',
      playerName: 'Guest Scorekeeper',
      nickname: 'Guest',
      ownerId: 'guest',
      totalScore: 0,
    );

    await Game.saveGameToDatabase(game, guestCreator);

    final participantGames = await fakeFirestore
        .collection('games')
        .where('participant_ids', arrayContains: 'registered-player-1')
        .get();
    expect(participantGames.docs, hasLength(1));
    expect(participantGames.docs.single.id, 'guest-cloud-game');

    final fetchedGames =
        await Game.fetchGamesForCurrentUser('registered-player-1');
    expect(fetchedGames, hasLength(1));
    expect(fetchedGames.single.name, 'Guest Cloud Game');
  });
}

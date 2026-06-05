import 'dart:convert';
import 'dart:math';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:random_x/random_x.dart';
import 'package:recase/recase.dart';
import 'package:word_generator/word_generator.dart';

class Game {
  Game(
      {required this.name,
      required this.course,
      required this.players,
      this.startTime,
      required this.scheduledTime,
      this.completedTime,
      String? id,
      String? status})
      : id = id ?? const Uuid().v4(),
        status = status ?? "unstarted_game" {
    scores = _initializeScores(players, course.numberOfHoles);
  }

  factory Game.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    String? id = data['id'];
    final String name = data['name'];
    final Course course = Course.fromJson(data['course']);
    final List<PlayerGameInfo> players = List<PlayerGameInfo>.from(
        data['players']
            .map((playerData) => PlayerGameInfo.fromJson(playerData)));
    final DateTime? startTime = (data['start_time'] != null)
        ? DateTime.parse(data['start_time'])
        : null;
    final DateTime scheduledTime = (data['scheduled_time'] != null)
        ? DateTime.parse(data['scheduled_time'])
        : DateTime.now();
    final DateTime? completedTime = (data['completed_time'] != null)
        ? DateTime.parse(data['completed_time'])
        : null;
    String? status = data['status'];

    return Game(
        id: id,
        name: name,
        course: course,
        players: players,
        startTime: startTime,
        scheduledTime: scheduledTime,
        completedTime: completedTime,
        status: status);
  }

  factory Game.empty() {
    return Game(
      name: '',
      course: Course.empty(),
      players: [],
      scheduledTime: DateTime.now(),
      id: '',
    );
  }

  DateTime? completedTime;
  Course course;
  final String id;
  late final String name;
  final List<PlayerGameInfo> players;
  DateTime scheduledTime;
  late Map<PlayerGameInfo, Map<int, int>> scores;
  DateTime? startTime;
  String status = "unstarted_game";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course': course.toJson(),
      'players': players.map((player) => player.toJson()).toList(),
      'start_time': startTime?.toIso8601String(),
      'scheduled_time': scheduledTime.toIso8601String(),
      'completed_time': completedTime?.toIso8601String(),
      'status': status
    };
  }

  void addPlayer(PlayerGameInfo player) {
    if (players.length >= 6) {
      throw Exception('Maximum number of players reached');
    }
    players.add(player);
    scores[player] = {
      for (var holeNumber
          in List.generate(course.numberOfHoles, (index) => index + 1))
        holeNumber: 0
    }; // Initialize scores
  }

  void recordScore(PlayerGameInfo player, int holeNumber, int strokes) {
    if (!players.contains(player)) {
      throw Exception('Player is not part of the game');
    }

    if (!scores.containsKey(player)) {
      throw Exception('Player scores not initialized');
    }
    Utilities.debugPrintWithCallerInfo(
        "GameId: ${player.gameId}, Hole Number: $holeNumber, strokes: $strokes");
    scores[player]![holeNumber] = strokes;
    player.scores = scores[player]!.values.toList();
    player.scoreTimestamps.add(DateTime.now().toIso8601String());
    calculateTotalScore(player);
    getPlayerPosition(player);
  }

  int calculateTotalScore(PlayerGameInfo player) {
    if (!scores.containsKey(player)) {
      PlayerGameInfo? existingKey;
      for (final k in scores.keys) {
        if (k.playerId == player.playerId) {
          existingKey = k;
          break;
        }
      }
      if (existingKey != null) {
        scores[player] = scores[existingKey]!;
      } else {
        addPlayer(player);
      }
    }

    final List<int> playerScores = player.scores;
    if (playerScores.isEmpty) {
      player.totalScore = 0;
      return player.totalScore;
    }
    player.totalScore =
        playerScores.fold<int>(0, (totalSum, strokes) => totalSum + strokes);
    return player.totalScore;
  }

  List<PlayerGameInfo> getWinners() {
    if (players.isEmpty) {
      return [];
    }
    int? minScore;
    List<PlayerGameInfo> winners = [];

    for (final player in players) {
      final totalScore = calculateTotalScore(player);
      if (minScore == null || totalScore < minScore) {
        minScore = totalScore;
        winners = [player];
      } else if (totalScore == minScore) {
        winners.add(player);
      }
    }

    return winners;
  }

  List<PlayerGameInfo> getSortedPlayerScores() {
    final List<PlayerGameInfo> playerScores = [];
    for (PlayerGameInfo player in players) {
      int totalScore = calculateTotalScore(player);
      playerScores.add(PlayerGameInfo(
        playerId: player.playerId,
        gameId: player.gameId,
        scores: player.scores,
        playOrderPosition: player.playOrderPosition,
        place: player.place,
        totalScore: totalScore,
      ));
    }

    playerScores.sort((a, b) {
      if (a.totalScore != b.totalScore && b.totalScore != 0) {
        return a.totalScore.compareTo(b.totalScore);
      } else {
        return a.playerId
            .compareTo(b.playerId); // Sort by playerId when scores are tied
      }
    });
    return playerScores;
  }

  int getPlayerPosition(PlayerGameInfo player) {
    List<PlayerGameInfo> sortedPlayers = players.toList();
    sortedPlayers.sort((a, b) {
      int aTotalScore = calculateTotalScore(a);
      int bTotalScore = calculateTotalScore(b);
      if (aTotalScore != bTotalScore) {
        return aTotalScore.compareTo(bTotalScore);
      } else {
        return a.playerId.compareTo(b.playerId);
      }
    });

    for (var i = 0; i < sortedPlayers.length; i++) {
      PlayerGameInfo currentPlayer = sortedPlayers[i];
      int currentPosition = i + 1;
      int currentHoleIndex = 0;
      for (int j = 0; j < currentPlayer.scores.length; j++) {
        if (currentPlayer.scores[j] == 0) {
          currentHoleIndex = j;
          break;
        }
      }

      List<PlayerGameInfo> tiedPlayers = [];
      for (var j = 0; j < i; j++) {
        PlayerGameInfo previousPlayer = sortedPlayers[j];
        if (previousPlayer.scores.length <= currentHoleIndex) {
          continue; // Skip players who haven't played the current hole yet
        }
        if (previousPlayer.totalScore == currentPlayer.totalScore) {
          tiedPlayers.add(previousPlayer);
        }
      }

      if (tiedPlayers.isNotEmpty &&
          currentPlayer.scores.isNotEmpty &&
          currentPlayer.scores[currentHoleIndex] != 0) {
        tiedPlayers.add(currentPlayer);
        tiedPlayers.sort((a, b) => a.playerId.compareTo(b.playerId));
        int tiedPosition = currentPosition - tiedPlayers.length + 1;
        for (var tiedPlayer in tiedPlayers) {
          tiedPlayer.place =
              '${Utilities.getPositionString(tiedPosition)} (tied)';
        }
      } else {
        currentPlayer.place = Utilities.getPositionString(currentPosition);
      }
      tiedPlayers.clear(); // Clear tied players list for the next iteration
    }

    return sortedPlayers.indexWhere((p) => p.playerId == player.playerId) + 1;
  }

  static String generateRandomGameName([String? suffix = "Game"]) {
    final wordGenerator = WordGenerator();
    return "${wordGenerator.randomNoun().titleCase} ${wordGenerator.randomNoun().titleCase} $suffix";
  }

  static List<Game> generateRandomGames(int? numberOfGames) {
    List<Game> games = [];
    Random rnd = Random();
    const int minPlayerStrokes = 1;
    const int maxPlayerStrokes = 5;
    const List<int> totalNumberOfHoles = [9, 18];
    const int minHolePar = 2;
    const int maxHolePar = 5;

    DateTime startDate = DateTime.now().subtract(const Duration(days: 365));
    DateTime endDate = DateTime.now();
    List<DateTime> randomGameDateList = RndX.generateRandomDates(
        count: numberOfGames!,
        start: startDate,
        end: endDate,
        uniqueList: true);
    randomGameDateList.sort((a, b) => b.compareTo(a));

    for (var i = 0; i < numberOfGames; i++) {
      String name = generateRandomGameName("Club");
      Map<int, int> parStrokes = {};
      int courseNumberOfHoles =
          totalNumberOfHoles[rnd.nextInt(totalNumberOfHoles.length)];
      for (int j = 0; j < courseNumberOfHoles; j++) {
        parStrokes[j + 1] =
            minHolePar + rnd.nextInt(maxHolePar + 1 - minHolePar);
      }

      Game game = Game(
          name: generateRandomGameName(),
          course: Course(
            id: i.toString(),
            name: name,
            numberOfHoles: courseNumberOfHoles,
            parStrokes: parStrokes,
          ),
          players: [],
          startTime: randomGameDateList[i],
          scheduledTime: randomGameDateList[i],
          completedTime: randomGameDateList[i],
          status: "completed");

      int numOfPlayers = 2 + rnd.nextInt((5 + 1 - 2));
      for (int l = 0; l < numOfPlayers; l++) {
        PlayerGameInfo player = PlayerGameInfo(
            playerId: (l + 1).toString(), gameId: game.id, scores: []);
        game.addPlayer(player);
      }

      for (int k = 0; k < courseNumberOfHoles; k++) {
        for (var player in game.players) {
          game.recordScore(
              player,
              k + 1,
              minPlayerStrokes +
                  rnd.nextInt((maxPlayerStrokes + 1 - minPlayerStrokes)));
        }
      }

      games.add(game);
    }

    return games;
  }

  static Future<void> saveLocalGame(Game gameToSaveLocally) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String gameString = jsonEncode(gameToSaveLocally.toJson());
    await prefs.setString(gameToSaveLocally.id, gameString);
  }

  static Future<void> initializeLocalGames(Player loggedInUser) async {
    try {
      await Game.adoptLocalGames(loggedInUser);
      Utilities.debugPrintWithCallerInfo("Loading games from database");
      final List<Game?> dbGames =
          await Game.fetchGamesForCurrentUser(loggedInUser.id);
      if (dbGames.isNotEmpty) {
        List<Game> loadedGames = dbGames.whereType<Game>().toList();
        for (Game loadedGame in loadedGames) {
          await Game.saveLocalGame(
              loadedGame); //save games locally if we loaded them from db
        }
        Utilities.debugPrintWithCallerInfo(
            "Loaded games: ${dbGames.map((game) => game?.toJson())}");
      }
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          "Exception when initializing games: ${exception.toString()}");
    }
  }

  static Future<void> adoptLocalGames(Player loggedInUser) async {
    final localGames = await getLocallySavedGames();
    final adoptedPlayers = await Player.adoptLocalGuestPlayers(loggedInUser);
    for (final localGame in localGames.whereType<Game>()) {
      for (var index = 0; index < localGame.players.length; index++) {
        final playerInfo = localGame.players[index];
        final canonicalPlayer = adoptedPlayers[playerInfo.playerId];
        if (canonicalPlayer != null) {
          localGame.players[index] = PlayerGameInfo(
            playerId: canonicalPlayer.id,
            gameId: playerInfo.gameId,
            scores: playerInfo.scores,
            playOrderPosition: playerInfo.playOrderPosition,
            place: playerInfo.place,
            totalScore: playerInfo.totalScore,
            strokes: playerInfo.strokes,
            scoreTimestamps: playerInfo.scoreTimestamps,
          );
        }
      }
      await saveLocalGame(localGame);
      await saveGameToDatabase(localGame, loggedInUser);
    }
  }

  static Future<void> clearLocallySavedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final games = await getLocallySavedGames();
    for (final game in games.whereType<Game>()) {
      await prefs.remove(game.id);
    }
  }

  static Future<List<Game?>> getLocallySavedGames(
      {List<String>? gameStatusTypes}) async {
    List<Game?> games = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Get all the keys
    final Set<String> keys = prefs.getKeys().cast<String>();
    // Iterate over the keys and check if the value is a JSON
    for (String key in keys) {
      if (key != "email" &&
          key != "loggedInUser" &&
          key != "courses" &&
          key != "guest_players") {
        dynamic value = prefs.get(key);
        Utilities.debugPrintWithCallerInfo(
            "Found shared preference: $key $value");
        if (value is String) {
          try {
            Utilities.debugPrintWithCallerInfo(
                "It's a JSON-formatted string: $json");
            Game savedGame = Game.fromJson(value);
            Utilities.debugPrintWithCallerInfo(
                "It's a Game-formatted string: ${savedGame.toJson()}");
            if (gameStatusTypes != null && gameStatusTypes.isNotEmpty) {
              Utilities.debugPrintWithCallerInfo(
                  "Loading games of type $gameStatusTypes");
              for (String statusType in gameStatusTypes) {
                if (savedGame.status == statusType) {
                  Utilities.debugPrintWithCallerInfo(
                      "*** found ${savedGame.name}");
                  games.add(savedGame);
                }
              }
            } else {
              games.add(savedGame);
            }
          } catch (e) {
            Utilities.debugPrintWithCallerInfo(
                "Not a JSON-formatted string. Plain value: $value");
          }
        } else if (value is List<String>) {
          Utilities.debugPrintWithCallerInfo("It's a List of strings: $value");
        } else {
          Utilities.debugPrintWithCallerInfo(
              "Value cannot be parsed. Type: ${value.runtimeType}");
        }
      }
    }
    return games;
  }

  static Future<List<Game>> fetchGamesForCurrentUser(
      String currentUserId) async {
    try {
      final creatorSnapshot = await DatabaseConnection.client
          .collection('games')
          .where('participant_ids', arrayContains: currentUserId)
          .orderBy('scheduled_time', descending: false)
          .get()
          .timeout(const Duration(seconds: 2));

      final participantSnapshot = await DatabaseConnection.client
          .collection('player_game_info')
          .where('player_id', isEqualTo: currentUserId)
          .get()
          .timeout(const Duration(seconds: 2));

      final Map<String, DocumentSnapshot<Map<String, dynamic>>> gameDocsById = {
        for (final doc in creatorSnapshot.docs) doc.id: doc,
      };

      final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = [];
      final List<String> gameIdsToFetch = [];

      for (final participantDoc in participantSnapshot.docs) {
        final gameId = participantDoc.data()['game_id'];
        if (gameId is String &&
            !gameDocsById.containsKey(gameId) &&
            !gameIdsToFetch.contains(gameId)) {
          gameIdsToFetch.add(gameId);
          futures.add(DatabaseConnection.client
              .collection('games')
              .doc(gameId)
              .get()
              .timeout(const Duration(seconds: 2)));
        }
      }

      if (futures.isNotEmpty) {
        final results = await Future.wait(futures);
        for (final gameDoc in results) {
          if (gameDoc.exists) {
            gameDocsById[gameDoc.id] = gameDoc;
          }
        }
      }

      final gameDocs = gameDocsById.values.toList()
        ..sort((a, b) => (a.data()!['scheduled_time'] as String)
            .compareTo(b.data()!['scheduled_time'] as String));

      Utilities.debugPrintWithCallerInfo("Fetching games: ${gameDocs.length}");

      // Convert the response data into a list of Game objects
      final List<Game> games = [];
      for (final doc in gameDocs) {
        var gameData = doc.data()!;
        gameData['id'] = doc.id;

        // Fetch players and courses if stored separately, or if they're embedded
        // Assuming we embed them for now or they are nested in Firestore
        final game = Game.fromJson(jsonEncode(gameData));
        games.add(game);
      }

      return games;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to get games for current user: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to get games for current user: ${e.message}');
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          "General failure loading games for current user: $exception");
      throw Exception(
          "General failure loading games for current user: $exception");
    }
  }

  static Future<void> saveGameToDatabase(Game game, Player creator) async {
    try {
      // 1. Prepare the game data to be saved
      Map<String, dynamic> gameData = {
        'id': game.id,
        'name': game.name,
        'course_id': game.course.id,
        'scheduled_time': game.scheduledTime.toIso8601String(),
        'start_time':
            (game.startTime != null) ? game.startTime!.toIso8601String() : null,
        'completed_time': (game.completedTime != null)
            ? game.completedTime!.toIso8601String()
            : null,
        'status': game.status,
        'creator_id': creator.id,
        'course': game.course.toJson(),
        'participant_ids':
            game.players.map((player) => player.playerId).toList(),
        'players': game.players.map((p) => p.toJson()).toList()
      };

      // 2. Save the game data to the games table
      await DatabaseConnection.client
          .collection('games')
          .doc(game.id)
          .set(gameData);
      Utilities.debugPrintWithCallerInfo("Saved game to database");

      // 3. Save player game info to the player_game_info subcollection
      bool playerUpdated = false;
      var batch = DatabaseConnection.client.batch();
      for (final player in game.players) {
        final playerGameInfoData = {
          'game_id': game.id,
          'player_id': player.playerId,
          'place': player.place,
          'play_order_position': player.playOrderPosition,
          'scores': player.scores,
          'total_score': player.totalScore,
          'score_timestamps': player.scoreTimestamps,
        };
        var pgiRef = DatabaseConnection.client
            .collection('player_game_info')
            .doc('${game.id}_${player.playerId}');
        batch.set(pgiRef, playerGameInfoData);
        playerUpdated = true;
      }
      await batch.commit();

      if (playerUpdated) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(game.id, jsonEncode(game.toJson()));
      }
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'DB Failed to update game: ${e.message}');
      throw DatabaseConnectionError('Failed to update game: ${e.message}');
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          'General failure to update game: $exception');
      throw Exception('Failed to update game: $exception');
    }
  }

  static Map<PlayerGameInfo, Map<int, int>> _initializeScores(
      List<PlayerGameInfo> players, int numberOfHoles) {
    final scores = <PlayerGameInfo, Map<int, int>>{};
    for (final player in players) {
      scores[player] = {
        for (var holeNumber
            in List.generate(numberOfHoles, (index) => index + 1))
          holeNumber: 0
      };
    }
    return scores;
  }
}

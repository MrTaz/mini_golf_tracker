import 'dart:convert';
import 'dart:math';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:random_x/random_x.dart';
import 'package:recase/recase.dart';
import 'package:word_generator/word_generator.dart';

class Game {
  late final String name;
  final String id;
  Course course;
  final List<PlayerGameInfo> players;
  DateTime? startTime;
  DateTime scheduledTime;
  DateTime? completedTime;
  String status = "unstarted_game";
  late Map<PlayerGameInfo, Map<int, int>> scores;

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

  factory Game.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    String? id = data['id'];
    final String name = data['name'];
    final Course course = Course.fromJson(data['course']);
    final List<PlayerGameInfo> players =
        List<PlayerGameInfo>.from(data['players'].map((playerData) => PlayerGameInfo.fromJson(playerData)));
    final DateTime? startTime = (data['start_time'] != null) ? DateTime.parse(data['start_time']) : null;
    final DateTime scheduledTime =
        (data['scheduled_time'] != null) ? DateTime.parse(data['scheduled_time']) : DateTime.now();
    final DateTime? completedTime = (data['completed_time'] != null) ? DateTime.parse(data['completed_time']) : null;
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

  static Map<PlayerGameInfo, Map<int, int>> _initializeScores(List<PlayerGameInfo> players, int numberOfHoles) {
    final scores = <PlayerGameInfo, Map<int, int>>{};
    for (final player in players) {
      scores[player] = {for (var holeNumber in List.generate(numberOfHoles, (index) => index + 1)) holeNumber: 0};
    }
    return scores;
  }

  void addPlayer(PlayerGameInfo player) {
    if (players.length >= 6) {
      throw Exception('Maximum number of players reached');
    }
    players.add(player);
    scores[player] = {
      for (var holeNumber in List.generate(course.numberOfHoles, (index) => index + 1)) holeNumber: 0
    }; // Initialize scores
  }

  void recordScore(PlayerGameInfo player, int holeNumber, int strokes) {
    if (!players.contains(player)) {
      throw Exception('Player is not part of the game');
    }

    if (!scores.containsKey(player)) {
      throw Exception('Player scores not initialized');
    }
    Utilities.debugPrintWithCallerInfo("GameId: ${player.gameId}, Hole Number: $holeNumber, strokes: $strokes");
    scores[player]![holeNumber] = strokes;
    player.scores = scores[player]!.values.toList();
    calculateTotalScore(player);
    getPlayerPosition(player);
  }

  int calculateTotalScore(PlayerGameInfo player) {
    // if (!scores.containsKey(player)) {
    //   addPlayer(player);
    // }

    final List<int> playerScores = player.scores;
    if (playerScores.isEmpty) {
      throw Exception('Player scores not initialized');
    }
    player.totalScore = playerScores.fold<int>(0, (sum, strokes) => sum + strokes);
    return player.totalScore;
  }

  PlayerGameInfo getWinner() {
    PlayerGameInfo? winner;
    int? minScore;

    for (final player in players) {
      final totalScore = calculateTotalScore(player);
      if (minScore == null || totalScore <= minScore) {
        minScore = totalScore;
        winner = player;
        // TODO: deal with multiple winners
      }
    }

    return winner!;
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
        return a.playerId.compareTo(b.playerId); // Sort by playerId when scores are tied
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

      if (tiedPlayers.isNotEmpty && currentPlayer.scores[currentHoleIndex] != 0) {
        tiedPlayers.add(currentPlayer);
        tiedPlayers.sort((a, b) => a.playerId.compareTo(b.playerId));
        int tiedPosition = currentPosition - tiedPlayers.length + 1;
        for (var tiedPlayer in tiedPlayers) {
          tiedPlayer.place = '${Utilities.getPositionString(tiedPosition)} (tied)';
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
    List<DateTime> randomGameDateList =
        RndX.generateRandomDates(count: numberOfGames!, start: startDate, end: endDate, uniqueList: true);
    randomGameDateList.sort((a, b) => b.compareTo(a));

    for (var i = 0; i < numberOfGames; i++) {
      String name = generateRandomGameName("Club");
      Map<int, int> parStrokes = {};
      int courseNumberOfHoles = totalNumberOfHoles[rnd.nextInt(totalNumberOfHoles.length)];
      for (int j = 0; j < courseNumberOfHoles; j++) {
        parStrokes[j + 1] = minHolePar + rnd.nextInt(maxHolePar + 1 - minHolePar);
      }

      Game game = Game(
          name: generateRandomGameName(),
          course: Course(
            id: i,
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
        PlayerGameInfo player = PlayerGameInfo(playerId: l + 1, gameId: game.id, scores: []);
        game.addPlayer(player);
      }

      for (int k = 0; k < courseNumberOfHoles; k++) {
        for (var player in game.players) {
          game.recordScore(player, k + 1, minPlayerStrokes + rnd.nextInt((maxPlayerStrokes + 1 - minPlayerStrokes)));
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
      Utilities.debugPrintWithCallerInfo("Loading games from database");
      final List<Game?> dbGames = await Game.fetchGamesForCurrentUser(loggedInUser.id);
      if (dbGames.isNotEmpty) {
        List<Game> loadedGames = dbGames.whereType<Game>().toList();
        for (Game loadedGame in loadedGames) {
          await Game.saveLocalGame(loadedGame); //save games locally if we loaded them from db
        }
        Utilities.debugPrintWithCallerInfo("Loaded games: ${dbGames.map((game) => game?.toJson())}");
      }
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo("Exception when initializing games: ${exception.toString()}");
    }
  }

  static Future<List<Game?>> getLocallySavedGames({List<String>? gameStatusTypes}) async {
    List<Game?> games = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Get all the keys
    final Set<String> keys = prefs.getKeys().cast<String>();
    // Iterate over the keys and check if the value is a JSON
    for (String key in keys) {
      if (key != "email" && key != "loggedInUser" && key != "courses") {
        dynamic value = prefs.get(key);
        Utilities.debugPrintWithCallerInfo("Found shared preference: $key $value");
        if (value is String) {
          try {
            Utilities.debugPrintWithCallerInfo("It's a JSON-formatted string: $json");
            Game savedGame = Game.fromJson(value);
            Utilities.debugPrintWithCallerInfo("It's a Game-formatted string: ${savedGame.toJson()}");
            if (gameStatusTypes != null && gameStatusTypes.isNotEmpty) {
              Utilities.debugPrintWithCallerInfo("Loading games of type $gameStatusTypes");
              for (String statusType in gameStatusTypes) {
                if (savedGame.status == statusType) {
                  Utilities.debugPrintWithCallerInfo("*** found ${savedGame.name}");
                  games.add(savedGame);
                }
              }
            } else {
              games.add(savedGame);
            }
          } catch (e) {
            Utilities.debugPrintWithCallerInfo("Not a JSON-formatted string. Plain value: $value");
          }
        } else if (value is List<String>) {
          Utilities.debugPrintWithCallerInfo("It's a List of strings: $value");
        } else {
          Utilities.debugPrintWithCallerInfo("Value cannot be parsed. Type: ${value.runtimeType}");
        }
      }
    }
    return games;
  }

  static Future<List<Game>> fetchGamesForCurrentUser(int currentUserId) async {
    try {
      // Fetch the games from the database where the current user is a player
      final response = await db
          .from('games')
          .select('*, players:player_game_info(*), course:courses(*)')
          .eq('creator_id', currentUserId)
          // .or('players_game_info.player_id.eq.$currentUserId')
          .order('scheduled_time', ascending: true);

      Utilities.debugPrintWithCallerInfo("Fetching games: $response");

      // Convert the response data into a list of Game objects
      final List<Game> games = [];
      if (response is List<dynamic> && response.isNotEmpty) {
        for (final gameData in response) {
          final game = Game.fromJson(jsonEncode(gameData));
          games.add(game);
        }
      }

      return games;
    } on PostgrestException catch (e) {
      Utilities.debugPrintWithCallerInfo('Failed to get games for current user: ${e.message}');
      throw DatabaseConnectionError('Failed to get games for current user: ${e.message}');
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo("General failure loading games for current user: $exception");
      throw Exception("General failure loading games for current user: $exception");
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
        'start_time': (game.startTime != null) ? game.startTime!.toIso8601String() : null,
        'completed_time': (game.completedTime != null) ? game.completedTime!.toIso8601String() : null,
        'status': game.status,
        'creator_id': creator.id
      };

      // 2. Save the game data to the games table and get the saved game ID
      final gameResponse = await db.from('games').upsert([gameData]);
      Utilities.debugPrintWithCallerInfo("Saved game to database, returned ${gameResponse.toString()}");

      // 3. Save player game info to the player_game_info table
      bool playerUpdated = false;
      for (final player in game.players) {
        final playerGameInfoData = {
          'game_id': game.id,
          'player_id': player.playerId,
          'place': player.place,
          'play_order_position': player.playOrderPosition,
          'scores': player.scores,
          'total_score': player.totalScore,
        };
        final pgiResponse =
            await db.from('player_game_info').upsert([playerGameInfoData], onConflict: 'game_id, player_id');
        Utilities.debugPrintWithCallerInfo(
            "Saved player game info to database, $playerGameInfoData, returned ${pgiResponse.toString()}");
        if (pgiResponse != null) {
          //if response was not null
          if (!playerUpdated) {
            //only change the flag to true if it is still false.
            playerUpdated = true;
          }
        }
      }
      if (gameResponse != null && playerUpdated) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(game.id, game.toJson() as String);
      }
    } on PostgrestException catch (e) {
      Utilities.debugPrintWithCallerInfo('DB Failed to update player score: ${e.message}');
      throw DatabaseConnectionError('Failed to update player score: ${e.message}');
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo('General failure to update player score: $exception');
      throw Exception('Failed to update player score: $exception');
    }
  }
}

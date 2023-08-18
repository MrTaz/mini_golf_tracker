import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

import 'package:random_x/random_x.dart';
import 'package:recase/recase.dart';
import 'package:word_generator/word_generator.dart';

import 'course.dart';
import 'databaseconnectionerror.dart';
import 'player_game_info.dart';

class Game {
  late final String name;
  final String id;
  Course course;
  final List<PlayerGameInfo> players;
  DateTime? startTime;
  DateTime scheduledTime;
  String status = "unstarted_game";
  late Map<PlayerGameInfo, Map<int, int>> scores;

  Game(
      {required this.name,
      required this.course,
      required this.players,
      this.startTime,
      required this.scheduledTime,
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
      'startTime': startTime?.toIso8601String(),
      'scheduledTime': scheduledTime.toIso8601String(),
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
    final DateTime? startTime = (data['startTime'] != null) ? DateTime.parse(data['startTime']) : null;
    final DateTime scheduledTime =
        (data['scheduledTime'] != null) ? DateTime.parse(data['scheduledTime']) : DateTime.now();
    String? status = data['status'];

    return Game(
        id: id,
        name: name,
        course: course,
        players: players,
        startTime: startTime,
        scheduledTime: scheduledTime,
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
    Utilities.debugPrintWithCallerInfo("CourseID: ${player.courseId}, Hole Number: $holeNumber, strokes: $strokes");
    scores[player]![holeNumber] = strokes;
    player.scores = scores[player]!.values.toList();
    calculateTotalScore(player);
    getPlayerPosition(player);
  }

  int calculateTotalScore(PlayerGameInfo player) {
    if (!scores.containsKey(player)) {
      addPlayer(player);
    }

    final playerScores = scores[player];
    if (playerScores == null) {
      throw Exception('Player scores not initialized');
    }

    player.totalScore = playerScores.values.reduce((sum, strokes) => sum + strokes);
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
        courseId: player.courseId,
        scores: scores[player]!.values.toList(), // Convert map values to a list
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
          tiedPlayer.place = '$tiedPosition${getOrdinalSuffix(tiedPosition)} (tied)';
        }
      } else {
        currentPlayer.place = getOrdinalString(currentPosition);
      }
      tiedPlayers.clear(); // Clear tied players list for the next iteration
    }

    return sortedPlayers.indexWhere((p) => p.playerId == player.playerId) + 1;
  }

  String getOrdinalSuffix(int number) {
    if (number % 10 == 1 && number % 100 != 11) {
      return 'st';
    } else if (number % 10 == 2 && number % 100 != 12) {
      return 'nd';
    } else if (number % 10 == 3 && number % 100 != 13) {
      return 'rd';
    } else {
      return 'th';
    }
  }

  String getOrdinalString(int number) {
    return '$number${getOrdinalSuffix(number)}';
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
          status: "completed");

      int numOfPlayers = 2 + rnd.nextInt((5 + 1 - 2));
      for (int l = 0; l < numOfPlayers; l++) {
        PlayerGameInfo player = PlayerGameInfo(playerId: l + 1, courseId: i, scores: []);
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

  static Future<List<Game>> fetchGamesForCurrentUser(int currentUserId) async {
    try {
      // Fetch the games from the database where the current user is a player
      final response = await supabase
          .from('games')
          .select('*, player_game_info!inner(*)')
          .eq('player_game_info.player_id', '$currentUserId')
          .order('scheduled_time', ascending: false);

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
      // Handle error if any
      if (kDebugMode) {
        print('Error fetching games: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to fetch games: ${e.message}');
    }
  }

  Future<void> saveGameToDatabase(Game game) async {
    try {
      // 1. Prepare the game data to be saved
      Map<String, dynamic> gameData = {
        'courseId': game.course.id,
        'players': game.players
            .map((player) => {
                  'playerId': player.playerId,
                  'courseId': player.courseId,
                  'scores': player.scores,
                })
            .toList(),
        'scheduledTime': game.scheduledTime.toIso8601String(),
        // Include any other relevant game data
      };

      // 2. Save the game data to the database
      final response = await supabase.from('games').insert([gameData]); //.execute();
    } on PostgrestException catch (e) {
      // Handle error if any
      if (kDebugMode) {
        print('Failed to save game: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to save game: ${e.message}');
    }
  }
}

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:random_x/random_x.dart';
import 'package:recase/recase.dart';
import 'package:word_generator/word_generator.dart';

import 'course.dart';
import 'player_game_info.dart';

class Game {
  final String name;
  final String id;
  final Course course;
  final List<PlayerGameInfo> players;
  DateTime startTime;
  late Map<PlayerGameInfo, Map<int, int>> scores;

  Game({
    required this.name,
    required this.course,
    required this.players,
    required this.startTime,
  }) : id = const Uuid().v4() {
    scores = _initializeScores(players, course.numberOfHoles);
  }

  Map<String, dynamic> toJson() {
    return {
      'couse': course.toJson(),
      'players': players.map((player) => player.toJson()).toList(),
      'startTime': startTime.toIso8601String()
    };
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

    scores[player]![holeNumber] = strokes;
    player.scores = scores[player]!.values.toList();
    player.place = getPlayerPositionStr(player);
    calculateTotalScore(player);
    debugPrint("Recorded Score ${player.toJson()}");
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
      if (minScore == null || totalScore < minScore) {
        minScore = totalScore;
        winner = player;
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
        totalScore: totalScore,
      ));
    }

    playerScores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    return playerScores;
  }

  int getPlayerPosition(PlayerGameInfo player) {
    final sortedPlayerScores = getSortedPlayerScores();
    final position = sortedPlayerScores.indexWhere((p) => p.playerId == player.playerId);
    return position + 1; // Add 1 to convert from zero-based index to position value
  }

  String getPlayerPositionStr(PlayerGameInfo player) {
    final place = getPlayerPosition(player);

    String suffix;
    if (place % 10 == 1 && place % 100 != 11) {
      suffix = 'st';
    } else if (place % 10 == 2 && place % 100 != 12) {
      suffix = 'nd';
    } else if (place % 10 == 3 && place % 100 != 13) {
      suffix = 'rd';
    } else {
      suffix = 'th';
    }
    return '$place$suffix';
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

    for (var i = 0; i < numberOfGames!; i++) {
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
      );

      int numOfPlayers = 2 + rnd.nextInt((5 + 1 - 2));
      for (int l = 0; l < numOfPlayers; l++) {
        PlayerGameInfo player = PlayerGameInfo(playerId: l + 1, courseId: i, scores: []);
        game.addPlayer(player);
        for (int k = 0; k < courseNumberOfHoles; k++) {
          game.recordScore(player, k + 1, minPlayerStrokes + rnd.nextInt((maxPlayerStrokes + 1 - minPlayerStrokes)));
        }
      }

      games.add(game);
    }

    return games;
  }

  // static List<Game> generateRandomGames(int? numberOfGames) {
  //   List<Game> games = [];
  //   Game defaultGame = Game(
  //       name: "My first game",
  //       course: Course(
  //           id: 0,
  //           name: "Atkinson Country Club",
  //           numberOfHoles: 9,
  //           parStrokes: {1: 5, 2: 5, 3: 5, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 5}),
  //       players: [],
  //       startTime: DateTime.now());
  //   PlayerGameInfo defaultPlayer = PlayerGameInfo(playerId: 1, courseId: 0, scores: []);
  //   defaultGame.addPlayer(defaultPlayer);
  //   for (int h = 1; h < 9; h++) {
  //     defaultGame.recordScore(defaultPlayer, h, 3);
  //   }
  //   games.add(defaultGame);

  //   Random rnd = Random();
  //   const int minPlayerStrokes = 1;
  //   const int maxPlayerStrokes = 5;

  //   const List<int> totalNumberOfHoles = [9, 18];

  //   const int minHolePar = 2;
  //   const int maxHolePar = 5;

  //   DateTime startDate = DateTime.now().subtract(const Duration(days: 365));
  //   DateTime endDate = DateTime.now();
  //   List<DateTime> randomGameDateList =
  //       RndX.generateRandomDates(count: numberOfGames!, start: startDate, end: endDate, uniqueList: true);
  //   randomGameDateList.sort((a, b) => b.compareTo(a));

  //   for (var i = 1; i < numberOfGames; i++) {
  //     String name = generateRandomGameName("Club");
  //     Map<int, int> parStrokes = {};
  //     int courseNumberOfHoles = totalNumberOfHoles[rnd.nextInt(totalNumberOfHoles.length)];
  //     for (int j = 0; j < courseNumberOfHoles; j++) {
  //       parStrokes[j + 1] = minHolePar + rnd.nextInt((maxHolePar + 1) - minHolePar);
  //     }

  //     Game game = Game(
  //         name: generateRandomGameName(),
  //         course: Course(
  //             id: i,
  //             name: name,
  //             numberOfHoles: courseNumberOfHoles,
  //             parStrokes: parStrokes), //{1: , 2: 5, 3: 5, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 5}),
  //         players: [
  //           // PlayerGameInfo(playerId: 1, courseId: i, scores: playerScores) //[1, 2, 3, 4, 5, 6, 7, 8, 9])
  //         ],
  //         startTime: randomGameDateList[i]);
  //     int numOfPlayers = 2 + rnd.nextInt((5 + 2) - 2);
  //     for (int l = 0; l < numOfPlayers; l++) {
  //       PlayerGameInfo player = PlayerGameInfo(playerId: l + 1, courseId: i, scores: []);
  //       game.addPlayer(player);
  //       for (int k = 0; k < courseNumberOfHoles; k++) {
  //         game.recordScore(player, k + 1, minPlayerStrokes + rnd.nextInt((maxPlayerStrokes + 1) - minPlayerStrokes));
  //       }
  //     }
  //     games.add(game);
  //   }
  //   return games;
  // }
}

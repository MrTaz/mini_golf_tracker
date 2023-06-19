import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/player.dart';
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
    debugPrint("CourseID: ${player.courseId}, Hole Number: $holeNumber, strokes: $strokes");
    scores[player]![holeNumber] = strokes;
    player.scores = scores[player]!.values.toList();
    calculateTotalScore(player);
    // player.place = getPlayerPosition(player) as String?;
    getPlayerPosition(player);
    // debugPrint("Recorded Score ${player.toJson()}");
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
    List<PlayerGameInfo> currentHolePlayers = [];

    int currentHoleIndex = 0;
    for (int i = 0; i < player.scores.length; i++) {
      if (player.scores[i] == 0) {
        currentHoleIndex = i;
        break;
      }
    }

    for (var otherPlayer in players) {
      if (otherPlayer.playerId == player.playerId) {
        // Skip the current player
        continue;
      }

      if (otherPlayer.scores.length > currentHoleIndex && otherPlayer.scores[currentHoleIndex] != 0) {
        // Player has played the current hole and recorded a score
        currentHolePlayers.add(otherPlayer);
      }
    }

    if (currentHolePlayers.length > 1) {
      currentHolePlayers.sort((a, b) {
        if (a.totalScore != b.totalScore) {
          return a.totalScore.compareTo(b.totalScore);
        } else {
          return a.playerId.compareTo(b.playerId); // Sort by playerId when scores are tied
        }
      });
    }

    for (var i = 0; i < currentHolePlayers.length; i++) {
      var currentPlayer = currentHolePlayers[i];
      int playerScore = currentPlayer.totalScore;
      int position = i + 1;

      int tiedCount = 0;
      for (final p in currentHolePlayers) {
        if (p.totalScore == playerScore) {
          tiedCount++;
        } else {
          break;
        }
      }

      if (tiedCount > 1) {
        int calculatedPosition = position - tiedCount;
        if (calculatedPosition <= 0) {
          calculatedPosition = position;
        }
        currentPlayer.place = '$calculatedPosition${getOrdinalSuffix(calculatedPosition)} (tied)';
      } else {
        currentPlayer.place = getOrdinalString(position);
      }
    }

    return currentHolePlayers.indexWhere((p) => p.playerId == player.playerId) + 1;
  }

  // int getPlayerPosition(PlayerGameInfo player) {
  //   debugPrint("getting player position: ${player.toJson()}");
  //   List<PlayerGameInfo> currentHolePlayers = [];
  //   int currentHole = player.scores.indexOf(0); // Find the current hole
  //   if (currentHole == -1) {
  //     currentHole =
  //         player.scores.length; // Player hasn't played any holes yet, set currentHole to the length of scores list
  //   }
  //   debugPrint("Current Hole $currentHole");
  //   // currentHolePlayers.add(player);
  //   // debugPrint("Current hole players: ${currentHolePlayers.toString()}, length: ${currentHolePlayers.length}");
  //   // debugPrint("Course info: ${course.id}, holes: ${course.numberOfHoles}");
  //   // debugPrint("Players info: ${players.toList()}");
  //   // for (var holeNumber = 0; holeNumber < course.numberOfHoles; holeNumber++) {
  //   // debugPrint("current hole: $holeNumber");
  //   for (var player in players) {
  //     // debugPrint("current player: ${player.toJson()}, ${player.scores.length}");
  //     // debugPrint("current hole: $holeNumber, ${player.scores[holeNumber]}");
  //     if (player.scores.length > 1) {
  //       // if (player.scores[holeNumber] == 0) {
  //       if (player.scores[currentHole - 1] == 0) {
  //         // debugPrint("skipping player... ${player.playerId}");
  //         continue; // Skip players who haven't played the current hole
  //       } else {
  //         if (!currentHolePlayers.contains(player)) {
  //           currentHolePlayers.add(player);
  //         }
  //       }
  //     } else {
  //       // debugPrint("skipping player... ${player.playerId}");
  //     }
  //   }
  //   // }
  //   // debugPrint("Current hole players: ${currentHolePlayers.toString()}");
  //   if (currentHolePlayers.length > 1) {
  //     // debugPrint("Sorting current players...");
  //     currentHolePlayers.sort((a, b) {
  //       if (a.totalScore != b.totalScore) {
  //         return a.totalScore.compareTo(b.totalScore);
  //       } else {
  //         return a.playerId.compareTo(b.playerId); // Sort by playerId when scores are tied
  //       }
  //     });
  //   }
  //   int playerScore = currentHolePlayers.firstWhere((p) => p.playerId == player.playerId).totalScore;
  //   int position =
  //       currentHolePlayers.indexWhere((p) => p.playerId == player.playerId) + 1; // Add 1, because the array starts at 0

  //   int tiedCount = 0;
  //   for (final p in currentHolePlayers) {
  //     if (p.totalScore == playerScore) {
  //       tiedCount++;
  //     } else {
  //       break;
  //     }
  //   }

  //   if (tiedCount > 1) {
  //     // this player has the same score as at least 1 other player
  //     int calculatedPosition = position - tiedCount;
  //     if (calculatedPosition <= 0) {
  //       calculatedPosition = position;
  //     }
  //     player.place = '$calculatedPosition${getOrdinalSuffix(calculatedPosition)} (tied)';
  //   } else {
  //     player.place = getOrdinalString(position);
  //   }
  //   debugPrint(
  //       'tiedCount: $tiedCount, playerID: ${player.playerId}, courseID: ${player.courseId}, totalScore: ${player.totalScore}, playerScore: $playerScore, place: ${player.place}');
  //   return position;
  // }

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

  String getPlayerPositionStr(PlayerGameInfo player) {
    final place = getPlayerPosition(player);
    final sortedPlayerScores = getSortedPlayerScores();
    final currentPlayerScore =
        sortedPlayerScores[sortedPlayerScores.indexWhere((p) => p.playerId == player.playerId)].totalScore;
    final tiedPlayers = sortedPlayerScores.where((p) => p.totalScore == currentPlayerScore).toList();
    final tiedCount = tiedPlayers.length;

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

    if (tiedCount > 1) {
      return '$place$suffix (tied)';
    } else {
      return '$place$suffix';
    }
  }
  // List<PlayerGameInfo> getSortedPlayerScores() {
  //   final List<PlayerGameInfo> playerScores = [];
  //   for (PlayerGameInfo player in players) {
  //     int totalScore = calculateTotalScore(player);
  //     playerScores.add(PlayerGameInfo(
  //       playerId: player.playerId,
  //       courseId: player.courseId,
  //       scores: scores[player]!.values.toList(), // Convert map values to a list
  //       place: player.place,
  //       totalScore: totalScore,
  //     ));
  //   }

  //   playerScores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
  //   return playerScores;
  // }

  // int getPlayerPosition(PlayerGameInfo player) {
  //   final sortedPlayerScores = getSortedPlayerScores();
  //   final position = sortedPlayerScores.indexWhere((p) => p.playerId == player.playerId);
  //   debugPrint(
  //       'Player gameid:playerid:postion: $sortedPlayerScores} - ${player.courseId}:${player.playerId}:$position');
  //   return position + 1; // Add 1 to convert from zero-based index to position value
  // }

  // String getPlayerPositionStr(PlayerGameInfo player) {
  //   final place = getPlayerPosition(player);

  //   String suffix;
  //   if (place % 10 == 1 && place % 100 != 11) {
  //     suffix = 'st';
  //   } else if (place % 10 == 2 && place % 100 != 12) {
  //     suffix = 'nd';
  //   } else if (place % 10 == 3 && place % 100 != 13) {
  //     suffix = 'rd';
  //   } else {
  //     suffix = 'th';
  //   }
  //   return '$place$suffix';
  // }

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
}

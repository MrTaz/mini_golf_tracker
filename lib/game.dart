import 'dart:math';
import 'package:uuid/uuid.dart';

import 'package:random_x/random_x.dart';
import 'package:recase/recase.dart';
import 'package:word_generator/word_generator.dart';

import 'course.dart';
import 'player.dart';
import 'playergameinfo.dart';

class Game {
  final String id;
  final Course course;
  final List<PlayerGameInfo> players;
  DateTime startTime;
  Map<PlayerGameInfo, Map<int, int>> scores;

  Game({
    required this.course,
    required this.players,
    required this.startTime,
  })  : id = const Uuid().v4(),
        scores = _initializeScores(players);

  static Map<PlayerGameInfo, Map<int, int>> _initializeScores(List<PlayerGameInfo> players) {
    final scores = <PlayerGameInfo, Map<int, int>>{};
    for (final player in players) {
      scores[player] = {};
    }
    return scores;
  }

  void addPlayer(PlayerGameInfo player) {
    if (players.length >= 6) {
      throw Exception('Maximum number of players reached');
    }
    players.add(player);
    scores[player] = Map<int, int>.fromIterable(
      List.generate(course.numberOfHoles, (index) => index + 1),
      key: (holeNumber) => holeNumber,
      value: (_) => 0,
    ); // Initialize scores
  }

  void recordScore(PlayerGameInfo player, int holeNumber, int strokes) {
    if (!players.contains(player)) {
      throw Exception('Player is not part of the game');
    }

    if (!scores.containsKey(player)) {
      throw Exception('Player scores not initialized');
    }

    scores[player]![holeNumber] = strokes;
  }

  int calculateTotalScore(PlayerGameInfo player) {
    final playerScores = scores[player];
    if (playerScores == null) {
      throw Exception('Player scores not initialized');
    }

    return playerScores.values.reduce((sum, strokes) => sum + strokes);
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

  Map<String, dynamic> toJson() {
    return {
      'couse': course.toJson(),
      'players': [...players],
      'startTime': startTime
    };
  }

  static List<Game> generateRandomGames(int? numberOfGames) {
    List<Game> games = [];
    Game defaultGame = Game(
        course: Course(
            id: 0,
            name: "Atkinson Country Club",
            numberOfHoles: 9,
            parStrokes: {1: 5, 2: 5, 3: 5, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 5}),
        players: [],
        startTime: DateTime.now());
    PlayerGameInfo defaultPlayer = PlayerGameInfo(playerId: 1, courseId: 0, scores: []);
    defaultGame.addPlayer(defaultPlayer);
    for (int h = 1; h < 9; h++) {
      defaultGame.recordScore(defaultPlayer, h, 3);
    }
    games.add(defaultGame);
    final wordGenerator = WordGenerator();

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

    for (var i = 1; i < numberOfGames; i++) {
      String name = "${wordGenerator.randomNoun().titleCase} ${wordGenerator.randomNoun().titleCase} Club";
      Map<int, int> parStrokes = {};
      int courseNumberOfHoles = totalNumberOfHoles[rnd.nextInt(totalNumberOfHoles.length)];
      for (int j = 0; j < courseNumberOfHoles; j++) {
        parStrokes[j + 1] = minHolePar + rnd.nextInt((maxHolePar + 1) - minHolePar);
      }

      Game game = Game(
          course: Course(
              id: i,
              name: name,
              numberOfHoles: courseNumberOfHoles,
              parStrokes: parStrokes), //{1: , 2: 5, 3: 5, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 5}),
          players: [
            // PlayerGameInfo(playerId: 1, courseId: i, scores: playerScores) //[1, 2, 3, 4, 5, 6, 7, 8, 9])
          ],
          startTime: randomGameDateList[i]);
      int numOfPlayers = 2 + rnd.nextInt((5 + 2) - 2);
      for (int l = 0; l < numOfPlayers; l++) {
        PlayerGameInfo player = PlayerGameInfo(playerId: l + 1, courseId: i, scores: []);
        game.addPlayer(player);
        for (int k = 0; k < courseNumberOfHoles; k++) {
          game.recordScore(player, k + 1, minPlayerStrokes + rnd.nextInt((maxPlayerStrokes + 1) - minPlayerStrokes));
        }
      }
      games.add(game);
    }
    return games;
  }
}

import 'course.dart';
import 'playergameinfo.dart';

class Game {
  final Course course;
  final List<PlayerGameInfo> players;
  DateTime startTime;
  Map<PlayerGameInfo, Map<int, int>> scores;

  Game({
    required this.course,
    required this.players,
    required this.startTime,
  }) : scores = _initializeScores(players);

  static Map<PlayerGameInfo, Map<int, int>> _initializeScores(
      List<PlayerGameInfo> players) {
    final scores = <PlayerGameInfo, Map<int, int>>{};
    for (final player in players) {
      scores[player] = {};
    }
    return scores;
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
}

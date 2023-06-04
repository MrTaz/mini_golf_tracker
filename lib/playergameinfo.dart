class PlayerGameInfo {
  final int playerId;
  final int courseId;
  final List<int> scores;
  int totalScore;

  PlayerGameInfo({required this.playerId, required this.courseId, required this.scores, this.totalScore = 0});

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'courseId': courseId,
      'scores': [...scores],
      'totalScore': totalScore
    };
  }
}

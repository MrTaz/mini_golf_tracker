class PlayerGameInfo {
  final int playerId;
  final int courseId;
  final List<int> scores;

  PlayerGameInfo({
    required this.playerId,
    required this.courseId,
    required this.scores,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'courseId': courseId,
      'scores': [...scores]
    };
  }
}

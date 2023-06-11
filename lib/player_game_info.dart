class PlayerGameInfo {
  final int playerId;
  final int courseId;
  String? place;
  List<int> scores;
  int totalScore;

  PlayerGameInfo(
      {required this.playerId, required this.courseId, required this.scores, this.place = "", this.totalScore = 0});

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'courseId': courseId,
      'scores': [...scores],
      'place': place,
      'totalScore': totalScore
    };
  }
}

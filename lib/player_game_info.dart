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
      'place': place == null ? "" : place,
      'totalScore': totalScore,
    };
  }

  factory PlayerGameInfo.fromJson(Map<String, dynamic> json) {
    final int playerId = json['playerId'];
    final int courseId = json['courseId'];
    final List<int> scores = List<int>.from(json['scores']);
    final String? place = json['place'];
    final int totalScore = json['totalScore'];

    return PlayerGameInfo(
      playerId: playerId,
      courseId: courseId,
      scores: scores,
      place: place,
      totalScore: totalScore,
    );
  }
}

class PlayerGameInfo {
  final int playerId;
  final String gameId;
  String? place;
  List<int> scores;
  int totalScore;

  PlayerGameInfo(
      {required this.playerId,
      required this.gameId,
      required this.scores,
      this.place = "", 
      this.totalScore = 0});

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'game_id': gameId, 
      'scores': [...scores],
      'place': place ?? "",
      'total_score': totalScore,
    };
  }

  factory PlayerGameInfo.fromJson(Map<String, dynamic> json) {
    final int playerId = json['player_id'];
    final String gameId = json['game_id'];
    final List<int> scores = List<int>.from(json['scores']);
    final String? place = json['place'];
    final int totalScore = json['total_score'];

    return PlayerGameInfo(
      playerId: playerId,
      gameId: gameId,
      scores: scores,
      place: place,
      totalScore: totalScore,
    );
  }
}

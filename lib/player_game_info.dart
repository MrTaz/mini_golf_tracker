class PlayerGameInfo {
  final int playerId;
  final String gameId;
  int? playOrderPosition;
  String? place;
  List<int> scores;
  int totalScore;

  PlayerGameInfo(
      {required this.playerId,
      required this.gameId,
      required this.scores,
      this.playOrderPosition = 0,
      this.place = "",
      this.totalScore = 0});

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'game_id': gameId,
      'scores': [...scores],
      'play_order_position': playOrderPosition,
      'place': place ?? "",
      'total_score': totalScore,
    };
  }

  factory PlayerGameInfo.fromJson(Map<String, dynamic> json) {
    final int playerId = json['player_id'];
    final String gameId = json['game_id'];
    final List<int> scores = List<int>.from(json['scores']);
    final int? playOrderPosition = json['play_order_position'];
    final String? place = json['place'];
    final int totalScore = json['total_score'];

    return PlayerGameInfo(
      playerId: playerId,
      gameId: gameId,
      scores: scores,
      playOrderPosition: playOrderPosition,
      place: place,
      totalScore: totalScore,
    );
  }
}

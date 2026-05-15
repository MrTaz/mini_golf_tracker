class PlayerGameInfo {
  PlayerGameInfo(
      {required this.playerId,
      required this.gameId,
      required this.scores,
      this.playOrderPosition = 0,
      this.place = "",
      this.totalScore = 0,
      this.strokes = 0});

  factory PlayerGameInfo.fromJson(Map<String, dynamic> json) {
    return PlayerGameInfo(
      playerId: json['player_id'],
      gameId: json['game_id'],
      scores: List<int>.from(json['scores']),
      playOrderPosition: json['play_order_position'],
      place: json['place'],
      totalScore: json['total_score'],
      strokes: json['strokes'] ?? 0,
    );
  }

  final String gameId;
  String? place;
  int? playOrderPosition;
  final String playerId;
  List<int> scores;
  int totalScore;
  int strokes;

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'game_id': gameId,
      'scores': scores,
      'play_order_position': playOrderPosition,
      'place': place,
      'total_score': totalScore,
      'strokes': strokes,
    };
  }
}

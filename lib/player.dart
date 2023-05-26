class Player {
  final int id;
  final String playerName;
  final String nickname;
  final String? email;
  final String? phoneNumber;
  final String? status;
  final num totalScore;
  final String? avatarImageLocation;

  Player(
      {required this.id,
      required this.playerName,
      required this.nickname,
      this.email,
      this.phoneNumber,
      this.status,
      required this.totalScore,
      this.avatarImageLocation});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
        id: json['id'],
        playerName: json['player_name'],
        nickname: json['nickname'],
        email: json['email'],
        phoneNumber: json['phone_number'],
        status: json['status'],
        totalScore: json['totalScore'],
        avatarImageLocation: json['avatarImageLocation']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_name': playerName,
      'nickname': nickname,
      'email': email,
      'phone_number': phoneNumber,
      'status': status,
      'totalScore': totalScore,
      'avatarImageLocation': avatarImageLocation
    };
  }
}

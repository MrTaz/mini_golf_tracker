class Player {
  final int id;
  final String playerName;
  final String nickname;
  final String? email;
  final String? phoneNumber;
  final String? status;
  final num totalScore;
  final String? avatarImageLocation;
  final int ownerId;

  Player(
      {required this.id,
      required this.playerName,
      required this.nickname,
      required this.ownerId,
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
        ownerId: json['owner_id'],
        email: json['email'],
        phoneNumber: json['phone_number'],
        status: json['status'],
        totalScore: json['total_score'],
        avatarImageLocation: json['avatar_image_location']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_name': playerName,
      'nickname': nickname,
      'owner_id': ownerId,
      'email': email,
      'phone_number': phoneNumber,
      'status': status,
      'total_score': totalScore,
      'avatar_image_location': avatarImageLocation
    };
  }

  static Player? getPlayerById(int playerId) {
    return Player.getAllPlayers().firstWhere((player) => player.id == playerId, orElse: () => null as Player);
  }

  static List<Player> getAllPlayers() {
    return [
      Player(
          id: 1,
          playerName: "Will",
          nickname: "Dad",
          ownerId: 1,
          totalScore: 50,
          email: "mrtaz28@gmail.com",
          avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
      Player(
          id: 2,
          playerName: "Mandi",
          nickname: "Mom",
          ownerId: 1,
          totalScore: 62,
          email: "pumkey@gmail.com",
          avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
      Player(
          id: 3,
          playerName: "Ava",
          nickname: "Aba",
          ownerId: 1,
          totalScore: 52,
          email: "princessavajayde@gmail.com",
          avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
      Player(
          id: 4,
          playerName: "Brayden",
          nickname: "Monkey",
          ownerId: 1,
          totalScore: 51,
          email: "hunter15511@gmail.com",
          avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
      Player(
          id: 5,
          playerName: "Collin",
          nickname: "Pumpkin",
          ownerId: 1,
          totalScore: 54,
          email: "pumkey41@gmail.com",
          avatarImageLocation: "assets/images/avatars_3d_avatar_28.png")
    ];
  }
}

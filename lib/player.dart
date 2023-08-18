import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/databaseconnectionerror.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/utilities.dart';

class Player {
  final int id;
  String playerName;
  String nickname;
  String? email;
  String? phoneNumber;
  String? status;
  num totalScore;
  String? avatarImageLocation;
  int ownerId;

  static List<Player> players = [];

  Player(
      {required this.id,
      required this.playerName,
      required this.nickname,
      required this.ownerId,
      required this.totalScore,
      this.email,
      this.phoneNumber,
      this.status,
      this.avatarImageLocation});

  // Factory method to create a Player object without populating fields
  factory Player.empty() {
    return Player(
      id: 0,
      playerName: '',
      nickname: '',
      ownerId: 0,
      totalScore: 0,
    );
  }

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

  Future<void> loadUserPlayers() async {
    if (players.isEmpty && !ownerId.isNaN) {
      final loadedPlayers = await _getAllPlayersFromDBByOwnerId(ownerId);
      players.addAll(loadedPlayers);
    }
  }

  List<Player> getAllPlayerFriends() {
    return players;
  }

  Player? getPlayerFriendById(int playerId) {
    return getAllPlayerFriends().firstWhere((player) => player.id == playerId, orElse: () => null as Player);
  }

  Player? getPlayerFriendByEmail(String email) {
    return players.firstWhere((player) => player.email == email, orElse: () => null as Player);
  }

  void addPlayerFriend(Player player) {
    players.add(player);
    Future.microtask(() async {
      Utilities.debugPrintWithCallerInfo('Adding ${player.playerName} as friend for $playerName');
      final response = await _addFriend(id, player.id);
    });
  }

  // Private method to add friend relationship
  Future<void> _addFriend(int playerId, int friendId) async {
    final response = await supabase.from('friends').upsert([
      {'player_id': playerId, 'friend_id': friendId},
      {'player_id': friendId, 'friend_id': playerId},
    ]);
  }

  static Future<Player?> getPlayerByEmailFromDB(String email) async {
    final response = await supabase.from('players').select().eq('email', email).single();

    if (response == null) {
      return null;
    }

    return Player.fromJson(response as Map<String, dynamic>);
  }

  static Future<Player?> _getPlayerByIdFromDB(int playerId) async {
    final response = await supabase.from('players').select().eq('id', playerId).single();

    // if (response.status == 400 || response.status == 401) {
    //   throw DatabaseConnectionError('Error retrieving player from Supabase');
    // }

    if (response == null) {
      return null;
    }

    return Player.fromJson(response as Map<String, dynamic>);
  }

  static Future<List<Player>> _getAllPlayersFromDBByOwnerId(int ownerId) async {
    final response = await supabase.from('players').select().eq('owner_id', ownerId);
    // if (response.status == 400 || response.status == 401) {
    //   throw DatabaseConnectionError('Error loading players from Supabase');
    // }
    return (response as List<dynamic>).map((data) => Player.fromJson(data)).toList();
  }

  Future<Player> createPlayer(String playerName, String email, String phoneNumber, String nickname) async {
    if (await _isDuplicatePlayer(email, phoneNumber)) {
      throw DatabaseConnectionError(
          'Player with the same email or phone number already exists'); //TODO: fix error handling
    }

    final createdPlayer = await _createPlayerInDB(playerName, email, phoneNumber, nickname);
    Utilities.debugPrintWithCallerInfo("Player saved to db, returning: ${createdPlayer.toJson()}");

    return createdPlayer;
  }

  Future<bool> _isDuplicatePlayer(String? email, String? phoneNumber) async {
    final response = await supabase.from('players').select().or('email.eq.$email,phone_number.eq.$phoneNumber');
    // if (response.status == 400 || response.status == 401) {
    //   throw DatabaseConnectionError('Error checking duplicate players from Supabase');
    // }
    Utilities.debugPrintWithCallerInfo("Is duplicate response: ${response}");
    return (response as List<dynamic>).isNotEmpty;
  }

  // Private method to create a player in Supabase and add friend relationship
  Future<Player> _createPlayerInDB(String playerName, String email, String phoneNumber, String nickname,
      {int? ownerId}) async {
    Map<String, dynamic> userToCreate = {
      "player_name": playerName,
      "email": email,
      "phone_number": phoneNumber,
      "nickname": nickname,
      "owner_id": ownerId ?? 0,
      "total_score": 0
    };

    final response = await supabase.from('players').upsert(userToCreate).select().single();
    Utilities.debugPrintWithCallerInfo("Create Player in Supabase response: ${response}");
    final playerWithoutOwnerId = Player.fromJson(response);
    Utilities.debugPrintWithCallerInfo("Created Player: ${playerWithoutOwnerId.toJson()}");
    Map<String, dynamic> responseWithOwnerId = {};
    if (playerWithoutOwnerId.ownerId == 0) {
      playerWithoutOwnerId.ownerId = playerWithoutOwnerId.id;
      Utilities.debugPrintWithCallerInfo(
          "updating Player owner id: ${playerWithoutOwnerId.ownerId} with ${playerWithoutOwnerId.id}");
      responseWithOwnerId = await supabase.from('players').upsert(playerWithoutOwnerId.toJson()).select().single();
    } else {
      responseWithOwnerId = playerWithoutOwnerId.toJson();
    }
    Utilities.debugPrintWithCallerInfo("Updated Player: $responseWithOwnerId");
    return Player.fromJson(responseWithOwnerId);
  }
}


// import 'package:mini_golf_tracker/databaseconnectionerror.dart';
// import 'package:mini_golf_tracker/main.dart';

// class Player {
//   final int id;
//   String playerName;
//   String nickname;
//   String? email;
//   String? phoneNumber;
//   String? status;
//   num totalScore;
//   String? avatarImageLocation;
//   int ownerId;

//   static List<Player> players = [
//     Player(
//         id: 1,
//         playerName: "Will",
//         nickname: "Dad",
//         ownerId: 1,
//         totalScore: 50,
//         email: "mrtaz28@gmail.com",
//         avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
//     Player(
//         id: 2,
//         playerName: "Mandi",
//         nickname: "Mom",
//         ownerId: 1,
//         totalScore: 62,
//         email: "pumkey@gmail.com",
//         avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
//     Player(
//         id: 3,
//         playerName: "Ava",
//         nickname: "Aba",
//         ownerId: 2,
//         totalScore: 52,
//         email: "princessavajayde@gmail.com",
//         avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
//     Player(
//         id: 4,
//         playerName: "Brayden",
//         nickname: "Monkey",
//         ownerId: 1,
//         totalScore: 51,
//         email: "hunter15511@gmail.com",
//         avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
//     Player(
//         id: 5,
//         playerName: "Collin",
//         nickname: "Pumpkin",
//         ownerId: 1,
//         totalScore: 54,
//         email: "pumkey41@gmail.com",
//         avatarImageLocation: "assets/images/avatars_3d_avatar_28.png")
//   ];

//   Player(
//       {required this.id,
//       required this.playerName,
//       required this.nickname,
//       required this.ownerId,
//       this.email,
//       this.phoneNumber,
//       this.status,
//       required this.totalScore,
//       this.avatarImageLocation});

//   factory Player.fromJson(Map<String, dynamic> json) {
//     return Player(
//         id: json['id'],
//         playerName: json['player_name'],
//         nickname: json['nickname'],
//         ownerId: json['owner_id'],
//         email: json['email'],
//         phoneNumber: json['phone_number'],
//         status: json['status'],
//         totalScore: json['total_score'],
//         avatarImageLocation: json['avatar_image_location']);
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'player_name': playerName,
//       'nickname': nickname,
//       'owner_id': ownerId,
//       'email': email,
//       'phone_number': phoneNumber,
//       'status': status,
//       'total_score': totalScore,
//       'avatar_image_location': avatarImageLocation
//     };
//   }

//   // Public method to get a player by ID
//   static Future<Player?> getPlayerById(int playerId) async {
//     return getPlayerByIdFromSupabase(playerId);
//   }

//   // Public method to get all players
//   static Future<List<Player>> getAllPlayers() async {
//     return _getAllPlayersFromSupabase();
//   }

//   // Public method to get a player by email
//   static Future<Player?> getPlayerByEmail(String email) async {
//     return getPlayerByEmailFromSupabase(email);
//   }

//   // Public method to add a player
//   static Future<void> addPlayer(Player player) async {
//     final newPlayer = await createPlayerInSupabase(player);
//     await addFriend(newPlayer.id, newPlayer.ownerId);
//   }

//   // Private method to get all players from Supabase
//   static Future<List<Player>> _getAllPlayersFromSupabase() async {
//     final data = await supabase.from('players').select();
//     if (data.status == 400 || data.status == 401) {
//       throw DatabaseConnectionError('Error loading players from Supabase');
//     }
//     return (data.data as List<dynamic>).map((data) => Player.fromJson(data)).toList();
//   }

//   // Private method to create a player in Supabase and add friend relationship
//   static Future<Player> createPlayerInSupabase(Player newPlayer) async {
//     final response = await supabase.from('players').upsert([newPlayer.toJson()]);

//     if (response.status == 400 || response.status == 401) {
//       throw DatabaseConnectionError('Error creating player in Supabase');
//     }

//     return newPlayer;
//   }

//   // Private method to add friend relationship
//   static Future<void> addFriend(int playerId, int friendId) async {
//     final response = await supabase.from('friends').upsert([
//       {'player_id': playerId, 'friend_id': friendId},
//       {'player_id': friendId, 'friend_id': playerId},
//     ]);
//     if (response.status == 400 || response.status == 401) {
//       throw DatabaseConnectionError('Error adding friend relationship');
//     }
//   }

//   // Private method to get a player by email from Supabase
//   static Future<Player?> getPlayerByEmailFromSupabase(String email) async {
//     final response = await supabase.from('players').select().eq('email', email).single().execute();

//     if (response.status == 400 || response.status == 401) {
//       throw DatabaseConnectionError('Error retrieving player from Supabase');
//     }

//     if (response.data == null) {
//       return null;
//     }

//     return Player.fromJson(response.data as Map<String, dynamic>);
//   }

//   // Private method to get a player by ID from Supabase
//   static Future<Player?> getPlayerByIdFromSupabase(int playerId) async {
//     final response = await supabase.from('players').select().eq('id', playerId).single().execute();

//     if (response.status == 400 || response.status == 401) {
//       throw DatabaseConnectionError('Error retrieving player from Supabase');
//     }

//     if (response.data == null) {
//       return null;
//     }

//     return Player.fromJson(response.data as Map<String, dynamic>);
//   }
// }

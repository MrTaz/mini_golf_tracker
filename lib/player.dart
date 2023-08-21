import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    Future.microtask(() async {
      Utilities.debugPrintWithCallerInfo('Checking if user is already in database');
      final isExistingUser = await _isDuplicatePlayer(player.email, player.phoneNumber);
      if(isExistingUser){
        Utilities.debugPrintWithCallerInfo('Getting player details');
        final updatedPlayer = await Player.getPlayerByEmailFromDB(player.email!);
        if(updatedPlayer != null){
          Utilities.debugPrintWithCallerInfo('Adding ${updatedPlayer.playerName} as friend for $playerName');
          final response = await _addFriend(id, updatedPlayer.id);
          players.add(updatedPlayer);
        }else{
          throw "Existing user, but unable to retrieve from database";
        }
      }else{
        final newPlayer = await _createPlayerInDB(player.playerName, player.email!, player.phoneNumber!, player.nickname, ownerId: ownerId);
        Utilities.debugPrintWithCallerInfo('New player friend created: ${newPlayer.toJson()}');
        Utilities.debugPrintWithCallerInfo('Adding ${newPlayer.playerName} as friend for $playerName');
        final response = await _addFriend(id, newPlayer.id);
        players.add(newPlayer);
      }
    });
    //TODO: Notify player that they have been added to a game
  }

  // Private method to add friend relationship
  Future<void> _addFriend(int playerId, int friendId) async {
    final response = await db.from('friends').upsert([
      {'player_id': playerId, 'friend_id': friendId},
      {'player_id': friendId, 'friend_id': playerId},
    ]);
  }

  static Future<Player?> getPlayerByEmailFromDB(String email) async {
    final response = await db.from('players').select().eq('email', email).single();

    if (response == null) {
      return null;
    }

    return Player.fromJson(response as Map<String, dynamic>);
  }

  static Future<Player?> _getPlayerByIdFromDB(int playerId) async {
    final response = await db.from('players').select().eq('id', playerId).single();

    // if (response.status == 400 || response.status == 401) {
    //   throw DatabaseConnectionError('Error retrieving player from Supabase');
    // }

    if (response == null) {
      return null;
    }

    return Player.fromJson(response as Map<String, dynamic>);
  }

  static Future<List<Player>> _getAllPlayersFromDBByOwnerId(int ownerId) async {
    final response = await db.from('players').select().eq('owner_id', ownerId);
    // if (response.status == 400 || response.status == 401) {
    //   throw DatabaseConnectionError('Error loading players from Supabase');
    // }
    return (response as List<dynamic>).map((data) => Player.fromJson(data)).toList();
  }

  static Future<void> updatePlayerScoreInDatabase(Player playerToUpdate) async {
    try {
      // Prepare the player's score data to be updated
      Map<String, dynamic> playerScoreData = {
        'total_score': playerToUpdate.totalScore,
      };

      // Update the player's score in the players table
      await db
          .from('players')
          .update(playerScoreData)
          .eq('id', playerToUpdate.id);
    } on PostgrestException catch (e) {
      Utilities.debugPrintWithCallerInfo('Failed to update player score: ${e.message}');
      throw DatabaseConnectionError('Failed to update player score: ${e.message}');
    }
  }

  Future<Player> createPlayer(String playerName, String email, String phoneNumber, String nickname) async {
    try {
      if (await _isDuplicatePlayer(email, phoneNumber)) {
        throw DatabaseConnectionError(
            'Player with the same email or phone number already exists'); //TODO: fix error handling
      }
      
      final createdPlayer = await _createPlayerInDB(playerName, email, phoneNumber, nickname);
      Utilities.debugPrintWithCallerInfo("Player saved to db, returning: ${createdPlayer.toJson()}");
      
      return createdPlayer;
    }  on PostgrestException catch (e) {
      Utilities.debugPrintWithCallerInfo('Failed to update player score: ${e.message}');
      throw DatabaseConnectionError('Failed to update player score: ${e.message}');
    }
  }

  Future<bool> _isDuplicatePlayer(String? email, String? phoneNumber) async {
    final response = await db.from('players').select().or('email.eq.$email,phone_number.eq.$phoneNumber');
    // if (response.status == 400 || response.status == 401) {
    //   throw DatabaseConnectionError('Error checking duplicate players from Supabase');
    // }
    Utilities.debugPrintWithCallerInfo("Is duplicate response: ${response}");
    return (response as List<dynamic>).isNotEmpty;
  }

  // Private method to create a player in Supabase and add friend relationship
  Future<Player> _createPlayerInDB(String playerName, String email, String phoneNumber, String nickname,
      {int? ownerId}) async {
    try {
      Map<String, dynamic> userToCreate = {
        "player_name": playerName,
        "email": email,
        "phone_number": phoneNumber,
        "nickname": nickname,
        "owner_id": ownerId ?? 0,
        "total_score": 0
      };
      
      final response = await db.from('players').upsert(userToCreate).select().single();
      Utilities.debugPrintWithCallerInfo("Create Player in Supabase response: ${response}");
      final playerWithoutOwnerId = Player.fromJson(response);
      Utilities.debugPrintWithCallerInfo("Created Player: ${playerWithoutOwnerId.toJson()}");
      Map<String, dynamic> responseWithOwnerId = {};
      if (playerWithoutOwnerId.ownerId == 0) {
        playerWithoutOwnerId.ownerId = playerWithoutOwnerId.id;
        Utilities.debugPrintWithCallerInfo(
            "updating Player owner id: ${playerWithoutOwnerId.ownerId} with ${playerWithoutOwnerId.id}");
        responseWithOwnerId = await db.from('players').upsert(playerWithoutOwnerId.toJson()).select().single();
      } else {
        responseWithOwnerId = playerWithoutOwnerId.toJson();
      }
      Utilities.debugPrintWithCallerInfo("Updated Player: $responseWithOwnerId");
      return Player.fromJson(responseWithOwnerId);
    } on PostgrestException catch (e) {
      Utilities.debugPrintWithCallerInfo('Failed to update player score: ${e.message}');
      throw DatabaseConnectionError('Failed to update player score: ${e.message}');
    }
  }
}
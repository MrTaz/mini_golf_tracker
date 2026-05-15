import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/utilities.dart';

class Player {
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
      id: '',
      playerName: '',
      nickname: '',
      ownerId: '',
      totalScore: 0,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
        id: json['id'] ?? '',
        playerName: json['player_name'] ?? '',
        nickname: json['nickname'] ?? '',
        ownerId: json['owner_id'] ?? '',
        email: json['email'],
        phoneNumber: json['phone_number'],
        status: json['status'],
        totalScore: json['total_score'] ?? 0,
        avatarImageLocation: json['avatar_image_location']);
  }

  static List<Player> players = [];
  String? avatarImageLocation;
  String? email;
  final String id;
  String nickname;
  String ownerId;
  String? phoneNumber;
  String playerName;
  String? status;
  num totalScore;

  FirebaseFirestore get db => DatabaseConnection.client;

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
    if (players.isEmpty && ownerId != '') {
      final loadedPlayers = await _getAllPlayersFromDBByOwnerId(ownerId);
      players.addAll(loadedPlayers);
    }
  }

  List<Player> getAllPlayerFriends() {
    return players;
  }

  Player? getPlayerFriendById(String playerId) {
    return players.firstWhere((player) => player.id == playerId, orElse: () => Player.empty());
  }

  Player? getPlayerFriendByEmail(String email) {
    return players.firstWhere((player) => player.email == email, orElse: () => Player.empty());
  }

  void addPlayerFriend(Player player) {
    Future.microtask(() async {
      Utilities.debugPrintWithCallerInfo(
          'Checking if user is already in database');
      final isExistingUser =
          await _isDuplicatePlayer(player.email, player.phoneNumber);
      if (isExistingUser) {
        Utilities.debugPrintWithCallerInfo('Getting player details');
        final updatedPlayer =
            await Player.getPlayerByEmailFromDB(player.email!);
        if (updatedPlayer != null) {
          Utilities.debugPrintWithCallerInfo(
              'Adding ${updatedPlayer.playerName} as friend for $playerName');
          await _addFriend(id, updatedPlayer.id);
          players.add(updatedPlayer);
        } else {
          throw "Existing user, but unable to retrieve from database";
        }
      } else {
        final newPlayer = await _createPlayerInDB(player.playerName,
            player.email!, player.phoneNumber!, player.nickname,
            ownerId: ownerId);
        Utilities.debugPrintWithCallerInfo(
            'New player friend created: ${newPlayer.toJson()}');
        Utilities.debugPrintWithCallerInfo(
            'Adding ${newPlayer.playerName} as friend for $playerName');
        await _addFriend(id, newPlayer.id);
        players.add(newPlayer);
      }
    });
    //TODO: Notify player that they have been added to a game
  }

  static Future<Player?> getPlayerByEmailFromDB(String email) async {
    final snapshot =
        await DatabaseConnection.client.collection('players').where('email', isEqualTo: email).limit(1).get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    var data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return Player.fromJson(data);
  }

  static Future<void> updatePlayerScoreInDatabase(Player playerToUpdate) async {
    try {
      // Prepare the player's score data to be updated
      Map<String, dynamic> playerScoreData = {
        'total_score': playerToUpdate.totalScore,
      };

      // Update the player's score in the players table
      await DatabaseConnection.client
          .collection('players')
          .doc(playerToUpdate.id)
          .update(playerScoreData);
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to update player score: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to update player score: ${e.message}');
    }
  }

  static Future<Player> createPlayer(String playerName, String email,
      String phoneNumber, String nickname) async {
    try {
      if (await _isDuplicatePlayer(email, phoneNumber)) {
        throw DatabaseConnectionError(
            'Player with the same email or phone number already exists'); //TODO: fix error handling
      }

      final createdPlayer =
          await _createPlayerInDB(playerName, email, phoneNumber, nickname);
      Utilities.debugPrintWithCallerInfo(
          "Player saved to db, returning: ${createdPlayer.toJson()}");

      return createdPlayer;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to create player: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to create player: ${e.message}');
    }
  }

  // Private method to add friend relationship
  Future<void> _addFriend(String playerId, String friendId) async {
    await db.collection('friends').doc('${playerId}_$friendId').set({
      'player_id': playerId,
      'friend_id': friendId,
    });
    await db.collection('friends').doc('${friendId}_$playerId').set({
      'player_id': friendId,
      'friend_id': playerId,
    });
  }

  static Future<List<Player>> _getAllPlayersFromDBByOwnerId(String ownerId) async {
    final snapshot = await DatabaseConnection.client.collection('players').where('owner_id', isEqualTo: ownerId).get();
    
    return snapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id;
      return Player.fromJson(data);
    }).toList();
  }

  static Future<bool> _isDuplicatePlayer(String? email, String? phoneNumber) async {
    final snapshot = await DatabaseConnection.client
        .collection('players')
        .where(Filter.or(
          Filter('email', isEqualTo: email),
          Filter('phone_number', isEqualTo: phoneNumber)
        )).limit(1).get();

    return snapshot.docs.isNotEmpty;
  }

  static Future<Player> _createPlayerInDB(
      String playerName, String email, String phoneNumber, String nickname,
      {String? ownerId}) async {
    try {
      Map<String, dynamic> userToCreate = {
        "player_name": playerName,
        "email": email,
        "phone_number": phoneNumber,
        "nickname": nickname,
        "owner_id": ownerId ?? '',
        "total_score": 0
      };

      final docRef = await DatabaseConnection.client.collection('players').add(userToCreate);
      var doc = await docRef.get();
      var data = doc.data()!;
      data['id'] = doc.id;
      
      final playerWithoutOwnerId = Player.fromJson(data);
      
      if (playerWithoutOwnerId.ownerId == '') {
        playerWithoutOwnerId.ownerId = playerWithoutOwnerId.id;
        await docRef.update({'owner_id': playerWithoutOwnerId.id});
      }
      
      return playerWithoutOwnerId;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to create player in DB: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to create player in DB: ${e.message}');
    }
  }
}

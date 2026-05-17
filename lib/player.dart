import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
        final newPlayer = await Player.createPlayer(
          player.playerName,
          player.nickname,
          email: player.email,
          phoneNumber: player.phoneNumber,
          ownerId: ownerId,
        );
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

  static Future<Player?> fetchPlayerFromDatabase(String id) async {
    final doc = await DatabaseConnection.client.collection('players').doc(id).get();
    if (!doc.exists) return null;
    
    var data = doc.data()!;
    data['id'] = doc.id;
    return Player.fromJson(data);
  }

  static Future<Player?> getPlayerByEmailFromDB(String email) async {
    final snapshot =
        await DatabaseConnection.client.collection('players').where('email', isEqualTo: email).get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    // If there are multiple profiles with the same email, prioritize the one
    // matching the current authenticated user's ID.
    if (Firebase.apps.isNotEmpty) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final matchingDocs = snapshot.docs.where((doc) => doc.id == currentUser.uid);
          final matchesUser = matchingDocs.isNotEmpty ? matchingDocs.first : snapshot.docs.first;
          var data = matchesUser.data();
          data['id'] = matchesUser.id;
          return Player.fromJson(data);
        }
      } catch (e) {
        Utilities.debugPrintWithCallerInfo('Error accessing FirebaseAuth in getPlayerByEmailFromDB: $e');
      }
    }

    // Otherwise, prioritize the self-owned profile (id == owner_id)
    // representing a real authenticated account rather than an offline guest profile.
    final selfOwnedDocs = snapshot.docs.where((doc) => doc.id == doc.data()['owner_id']);
    final matchesSelfOwned = selfOwnedDocs.isNotEmpty ? selfOwnedDocs.first : snapshot.docs.first;
    var data = matchesSelfOwned.data();
    data['id'] = matchesSelfOwned.id;
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

  static Future<Player> createPlayer(
    String playerName,
    String nickname, {
    String? email,
    String? phoneNumber,
    String? id,
    String? ownerId,
  }) async {
    try {
      if (email != null && email.isNotEmpty) {
        final existingPlayer = await getPlayerByEmailFromDB(email);
        if (existingPlayer != null) {
          if (id != null && existingPlayer.id != id) {
            // The old profile has a different ID (e.g. a UUID from a pre-Firebase era).
            // We cannot delete it because its owner_id doesn't match the current auth UID.
            // Simply proceed to create the new canonical profile under the Firebase UID.
            // getPlayerByEmailFromDB already prioritises the UID-matched doc, so the
            // old record will be naturally superseded and is harmless.
            Utilities.debugPrintWithCallerInfo(
                'Found existing profile with different ID: ${existingPlayer.id}. '
                'Proceeding to create canonical profile under Firebase UID: $id');
          } else if (id != null && existingPlayer.id == id) {
            return existingPlayer;
          } else {
            throw DatabaseConnectionError(
                'Player with the same email already exists');
          }
        }
      }

      // Also check phone number duplicate just in case
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final snapshot = await DatabaseConnection.client
            .collection('players')
            .where('phone_number', isEqualTo: phoneNumber)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final existingId = snapshot.docs.first.id;
          if (id != null && existingId != id) {
            // Same as the email case: the old profile has a UUID owner_id that
            // doesn't match the Firebase UID, so delete will always be denied.
            // Proceed to create the canonical profile under the Firebase UID.
            Utilities.debugPrintWithCallerInfo(
                'Found existing profile by phone with different ID: $existingId. '
                'Proceeding to create canonical profile under Firebase UID: $id');
          } else if (id != null && existingId == id) {
            var data = snapshot.docs.first.data();
            data['id'] = existingId;
            return Player.fromJson(data);
          } else {
            throw DatabaseConnectionError(
                'Player with the same phone number already exists');
          }
        }
      }

      final docRef = id != null 
          ? DatabaseConnection.client.collection('players').doc(id)
          : DatabaseConnection.client.collection('players').doc();
          
      final player = Player(
        id: docRef.id,
        playerName: playerName,
        nickname: nickname,
        ownerId: ownerId ?? docRef.id,
        totalScore: 0,
        email: email,
        phoneNumber: phoneNumber,
      );

      await docRef.set(player.toJson());

      Utilities.debugPrintWithCallerInfo(
          "Player saved to db, returning: ${player.toJson()}");

      return player;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to create player: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to create player: ${e.message}');
    }
  }

  // Private method to add friend relationship
  Future<void> _addFriend(String playerId, String friendId) async {
    await DatabaseConnection.client.collection('friends').doc('${playerId}_$friendId').set({
      'player_id': playerId,
      'friend_id': friendId,
    });
    await DatabaseConnection.client.collection('friends').doc('${friendId}_$playerId').set({
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
    List<Filter> filters = [];
    if (email != null && email.isNotEmpty) {
      filters.add(Filter('email', isEqualTo: email));
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      filters.add(Filter('phone_number', isEqualTo: phoneNumber));
    }

    if (filters.isEmpty) return false;

    final snapshot = await DatabaseConnection.client
        .collection('players')
        .where(Filter.or(filters[0], filters.length > 1 ? filters[1] : filters[0]))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

}

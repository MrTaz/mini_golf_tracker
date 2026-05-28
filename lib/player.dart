import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mini_golf_tracker/contact_identity.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Player {
  Player(
      {required this.id,
      required this.playerName,
      required this.nickname,
      required this.ownerId,
      required this.totalScore,
      this.email,
      this.phoneNumber,
      this.normalizedEmail,
      this.normalizedPhoneNumber,
      this.status,
      this.claimedByUid,
      this.shareName = true,
      this.shareEmail = true,
      this.sharePhone = true,
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
        normalizedEmail: json['normalized_email'] ??
            ContactIdentity.normalizeEmail(json['email']),
        normalizedPhoneNumber: json['normalized_phone_number'] ??
            ContactIdentity.normalizePhoneNumber(json['phone_number']),
        status: json['status'],
        claimedByUid: json['claimed_by_uid'],
        shareName: json['share_name'] ?? true,
        shareEmail: json['share_email'] ?? true,
        sharePhone: json['share_phone'] ?? true,
        totalScore: json['total_score'] ?? 0,
        avatarImageLocation: json['avatar_image_location']);
  }

  static List<Player> players = [];
  static const String _localGuestPlayersKey = 'guest_players';
  String? avatarImageLocation;
  String? email;
  final String id;
  String? claimedByUid;
  String nickname;
  String? normalizedEmail;
  String? normalizedPhoneNumber;
  String ownerId;
  bool shareName;
  bool shareEmail;
  bool sharePhone;
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
      'normalized_email': normalizedEmail,
      'normalized_phone_number': normalizedPhoneNumber,
      'status': status,
      'claimed_by_uid': claimedByUid,
      'share_name': shareName,
      'share_email': shareEmail,
      'share_phone': sharePhone,
      'total_score': totalScore,
      'avatar_image_location': avatarImageLocation
    };
  }

  Future<void> loadUserPlayers() async {
    if (players.isEmpty && id != '') {
      final loadedPlayers = await _getAllPlayersFromFriends(id);
      players.addAll(loadedPlayers);
    }
  }

  List<Player> getAllPlayerFriends() {
    return players;
  }

  static Future<void> loadLocalGuestPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final guestPlayersJson = prefs.getString(_localGuestPlayersKey);
    if (guestPlayersJson == null || guestPlayersJson.isEmpty) {
      return;
    }
    final decoded = jsonDecode(guestPlayersJson) as List<dynamic>;
    players = decoded
        .map(
            (playerJson) => Player.fromJson(playerJson as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveLocalGuestPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localGuestPlayersKey,
      jsonEncode(players.map((player) => player.toJson()).toList()),
    );
  }

  static Future<void> clearLocalGuestPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localGuestPlayersKey);
    players = [];
  }

  Player? getPlayerFriendById(String playerId) {
    return players.firstWhere((player) => player.id == playerId,
        orElse: () => Player.empty());
  }

  Player? getPlayerFriendByEmail(String email) {
    return players.firstWhere((player) => player.email == email,
        orElse: () => Player.empty());
  }

  Future<Player> addPlayerFriend(Player player) async {
    Utilities.debugPrintWithCallerInfo(
        'Checking if user is already in database');
    final canonicalPlayer = await resolveCanonicalPlayer(
      player,
      ownerIdForNewPlayer: id,
    );
    Utilities.debugPrintWithCallerInfo(
        'Adding ${canonicalPlayer.playerName} as friend for $playerName');
    await _addFriend(id, canonicalPlayer.id);
    final existingIndex =
        players.indexWhere((friend) => friend.id == canonicalPlayer.id);
    if (existingIndex == -1) {
      players.add(canonicalPlayer);
    } else {
      players[existingIndex] = canonicalPlayer;
    }
    return canonicalPlayer;
  }

  static Future<Player> resolveCanonicalPlayer(
    Player player, {
    required String ownerIdForNewPlayer,
  }) async {
    final existingPlayer =
        await Player.getPlayerByContactFromDB(player.email, player.phoneNumber);
    if (existingPlayer != null) {
      return existingPlayer;
    }

    return Player.createPlayer(
      player.playerName,
      player.nickname,
      email: player.email,
      phoneNumber: player.phoneNumber,
      ownerId: ownerIdForNewPlayer,
    );
  }

  static Future<Player> resolveGuestPlayer(Player player) async {
    final canonicalPlayer =
        await Player.getPlayerByContactFromDB(player.email, player.phoneNumber);
    return canonicalPlayer ?? player;
  }

  static Future<Map<String, Player>> adoptLocalGuestPlayers(
      Player loggedInUser) async {
    await loadLocalGuestPlayers();
    final adoptedPlayers = <String, Player>{};
    for (final guestPlayer in List<Player>.from(players)) {
      final canonicalPlayer = await loggedInUser.addPlayerFriend(guestPlayer);
      adoptedPlayers[guestPlayer.id] = canonicalPlayer;
    }
    await clearLocalGuestPlayers();
    return adoptedPlayers;
  }

  static Future<Player?> fetchPlayerFromDatabase(String id) async {
    final doc = await _safeGetDocument(
        DatabaseConnection.client.collection('players').doc(id));
    if (!doc.exists) return null;

    var data = doc.data()!;
    data['id'] = doc.id;
    return Player.fromJson(data);
  }

  static Future<Player?> fetchPlayerForAuthUid(String uid) async {
    final directMatch = await fetchPlayerFromDatabase(uid);
    if (directMatch != null) {
      return directMatch;
    }

    final snapshot = await _safeGetQuery(DatabaseConnection.client
        .collection('players')
        .where('claimed_by_uid', isEqualTo: uid)
        .limit(1));
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs[0];
    final data = doc.data();
    data['id'] = doc.id;
    return Player.fromJson(data);
  }

  static Future<Player?> getPlayerByEmailFromDB(String email) async {
    try {
      final normalizedEmail = ContactIdentity.normalizeEmail(email);
      if (normalizedEmail == null) {
        return null;
      }
      final reservedPlayer = await _getReservedPlayer('email', normalizedEmail);
      if (reservedPlayer != null) {
        return reservedPlayer;
      }

      var snapshot = await _safeGetQuery(DatabaseConnection.client
          .collection('players')
          .where('normalized_email', isEqualTo: normalizedEmail));
      if (snapshot.docs.isEmpty) {
        snapshot = await _safeGetQuery(DatabaseConnection.client
            .collection('players')
            .where('email', isEqualTo: email));
      }

      if (snapshot.docs.isEmpty) {
        return null;
      }

      // If there are multiple profiles with the same email, prioritize the one
      // matching the current authenticated user's ID.
      if (Firebase.apps.isNotEmpty) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            QueryDocumentSnapshot<Map<String, dynamic>>? matchesUser;
            for (final doc in snapshot.docs) {
              if (doc.id == currentUser.uid) {
                matchesUser = doc;
                break;
              }
            }
            matchesUser ??= snapshot.docs[0];
            var data = matchesUser.data();
            data['id'] = matchesUser.id;
            return Player.fromJson(data);
          }
        } catch (e) {
          Utilities.debugPrintWithCallerInfo(
              'Error accessing FirebaseAuth in getPlayerByEmailFromDB: $e');
        }
      }

      // Otherwise, prioritize the self-owned profile (id == owner_id)
      // representing a real authenticated account rather than an offline guest profile.
      QueryDocumentSnapshot<Map<String, dynamic>>? matchesSelfOwned;
      for (final doc in snapshot.docs) {
        if (doc.id == doc.data()['owner_id']) {
          matchesSelfOwned = doc;
          break;
        }
      }
      matchesSelfOwned ??= snapshot.docs[0];
      var data = matchesSelfOwned.data();
      data['id'] = matchesSelfOwned.id;
      return Player.fromJson(data);
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to fetch player by email: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to fetch player by email: ${e.message}');
    }
  }

  static Future<Player?> getPlayerByPhoneFromDB(String phoneNumber) async {
    try {
      final normalizedPhoneNumber =
          ContactIdentity.normalizePhoneNumber(phoneNumber);
      if (normalizedPhoneNumber == null) {
        return null;
      }
      final reservedPlayer =
          await _getReservedPlayer('phone', normalizedPhoneNumber);
      if (reservedPlayer != null) {
        return reservedPlayer;
      }

      var snapshot = await _safeGetQuery(DatabaseConnection.client
          .collection('players')
          .where('normalized_phone_number', isEqualTo: normalizedPhoneNumber)
          .limit(1));
      if (snapshot.docs.isEmpty) {
        snapshot = await _safeGetQuery(DatabaseConnection.client
            .collection('players')
            .where('phone_number', isEqualTo: phoneNumber)
            .limit(1));
      }
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs[0];
      final data = doc.data();
      data['id'] = doc.id;
      return Player.fromJson(data);
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to fetch player by phone: ${e.message}');
      throw DatabaseConnectionError(
          'Failed to fetch player by phone: ${e.message}');
    }
  }

  static Future<Player?> getPlayerByContactFromDB(
      String? email, String? phoneNumber) async {
    final normalizedEmail = ContactIdentity.normalizeEmail(email);
    final normalizedPhoneNumber =
        ContactIdentity.normalizePhoneNumber(phoneNumber);
    if (normalizedEmail != null) {
      final player = await getPlayerByEmailFromDB(email!);
      if (player != null) {
        return player;
      }
    }
    if (normalizedPhoneNumber != null) {
      return getPlayerByPhoneFromDB(phoneNumber!);
    }
    return null;
  }

  static Future<Player> claimPlayerForAuthUser({
    required String uid,
    required String email,
    String? phoneNumber,
    required String playerName,
    required String nickname,
  }) async {
    final existingPlayer = await getPlayerByContactFromDB(email, phoneNumber);
    if (existingPlayer != null) {
      existingPlayer.claimedByUid = uid;
      await DatabaseConnection.client
          .collection('players')
          .doc(existingPlayer.id)
          .update({'claimed_by_uid': uid});
      return existingPlayer;
    }

    return createPlayer(
      playerName,
      nickname,
      email: email,
      phoneNumber: phoneNumber,
      id: uid,
    );
  }

  static bool canVerifiedAuthUserClaimPlayer({
    required Player player,
    required String uid,
    required String? email,
    required bool emailVerified,
    required String? phoneNumber,
  }) {
    if (player.claimedByUid != null && player.claimedByUid != uid) {
      return false;
    }

    final normalizedEmail = ContactIdentity.normalizeEmail(email);
    final normalizedPhoneNumber =
        ContactIdentity.normalizePhoneNumber(phoneNumber);
    final emailMatches =
        (emailVerified || Utilities.isTestAccountBypass(email)) &&
            normalizedEmail != null &&
            normalizedEmail == player.normalizedEmail;
    final phoneMatches = normalizedPhoneNumber != null &&
        normalizedPhoneNumber == player.normalizedPhoneNumber;
    return emailMatches || phoneMatches;
  }

  static Future<Player?> claimPlayerForVerifiedAuthUser({
    required String uid,
    required String? email,
    required bool emailVerified,
    required String? phoneNumber,
  }) async {
    final normalizedEmail = ContactIdentity.normalizeEmail(email);
    final normalizedPhoneNumber =
        ContactIdentity.normalizePhoneNumber(phoneNumber);
    Player? candidate;
    if ((emailVerified || Utilities.isTestAccountBypass(email)) &&
        normalizedEmail != null) {
      candidate = await getPlayerByEmailFromDB(normalizedEmail);
    }
    candidate ??= normalizedPhoneNumber != null
        ? await getPlayerByPhoneFromDB(normalizedPhoneNumber)
        : null;
    if (candidate == null ||
        !canVerifiedAuthUserClaimPlayer(
          player: candidate,
          uid: uid,
          email: email,
          emailVerified: emailVerified,
          phoneNumber: phoneNumber,
        )) {
      return null;
    }

    candidate.claimedByUid = uid;
    await DatabaseConnection.client
        .collection('players')
        .doc(candidate.id)
        .update({'claimed_by_uid': uid});
    return candidate;
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
      final normalizedEmail = ContactIdentity.normalizeEmail(email);
      final normalizedPhoneNumber =
          ContactIdentity.normalizePhoneNumber(phoneNumber);
      final existingPlayer = await getPlayerByContactFromDB(email, phoneNumber);
      if (existingPlayer != null) {
        if (id != null && existingPlayer.id == id) {
          return existingPlayer;
        }
        throw DatabaseConnectionError(
            'Player with the same email or phone number already exists');
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
        email: normalizedEmail,
        phoneNumber: normalizedPhoneNumber,
        normalizedEmail: normalizedEmail,
        normalizedPhoneNumber: normalizedPhoneNumber,
        claimedByUid: id,
      );

      final reservations = _contactReservationsForPlayer(player);
      if (reservations.isEmpty) {
        await docRef.set(player.toJson());
      } else {
        await DatabaseConnection.client.runTransaction((transaction) async {
          for (final reservation in reservations) {
            final existingReservation = await transaction.get(reservation.ref);
            if (existingReservation.exists) {
              throw DatabaseConnectionError(
                  'Player with the same email or phone number already exists');
            }
          }

          transaction.set(docRef, player.toJson());
          for (final reservation in reservations) {
            transaction.set(reservation.ref, reservation.data);
          }
        });
      }

      Utilities.debugPrintWithCallerInfo(
          "Player saved to db, returning: ${player.toJson()}");

      return player;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to create player: ${e.message}');
      throw DatabaseConnectionError('Failed to create player: ${e.message}');
    }
  }

  static Future<void> updateUnclaimedPlayer(Player player) async {
    if (player.claimedByUid != null) {
      throw DatabaseConnectionError('Claimed players cannot be edited here');
    }

    player.email = ContactIdentity.normalizeEmail(player.email);
    player.phoneNumber =
        ContactIdentity.normalizePhoneNumber(player.phoneNumber);
    player.normalizedEmail = player.email;
    player.normalizedPhoneNumber = player.phoneNumber;

    final reservations = _contactReservationsForPlayer(player);
    await DatabaseConnection.client.runTransaction((transaction) async {
      for (final reservation in reservations) {
        final existingReservation = await transaction.get(reservation.ref);
        if (existingReservation.exists &&
            existingReservation.data()?['player_id'] != player.id) {
          throw DatabaseConnectionError(
              'Player with the same email or phone number already exists');
        }
      }

      final playerRef =
          DatabaseConnection.client.collection('players').doc(player.id);
      transaction.update(playerRef, player.toJson());
      for (final reservation in reservations) {
        transaction.set(reservation.ref, reservation.data);
      }
    });
  }

  // Private method to add friend relationship
  Future<void> _addFriend(String playerId, String friendId) async {
    await DatabaseConnection.client
        .collection('friends')
        .doc('${playerId}_$friendId')
        .set({
      'player_id': playerId,
      'friend_id': friendId,
    });
    await DatabaseConnection.client
        .collection('friends')
        .doc('${friendId}_$playerId')
        .set({
      'player_id': friendId,
      'friend_id': playerId,
    });
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> _safeGetDocument(
      DocumentReference<Map<String, dynamic>> ref) async {
    int retries = 0;
    while (true) {
      try {
        return await ref.get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' && retries < 3) {
          retries++;
          Utilities.debugPrintWithCallerInfo(
              'Firestore permission-denied race condition detected on get. Retry $retries/3 in 200ms...');
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          rethrow;
        }
      }
    }
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> _safeGetQuery(
      Query<Map<String, dynamic>> query) async {
    int retries = 0;
    while (true) {
      try {
        return await query.get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' && retries < 3) {
          retries++;
          Utilities.debugPrintWithCallerInfo(
              'Firestore permission-denied race condition detected on query. Retry $retries/3 in 200ms...');
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          rethrow;
        }
      }
    }
  }

  static Future<List<Player>> _getAllPlayersFromFriends(String playerId) async {
    try {
      final friendLinks = await _safeGetQuery(DatabaseConnection.client
          .collection('friends')
          .where('player_id', isEqualTo: playerId));

      final loadedPlayers = <Player>[];
      for (final friendLink in friendLinks.docs) {
        final friendId = friendLink.data()['friend_id'];
        if (friendId is! String) {
          continue;
        }
        final friend = await fetchPlayerFromDatabase(friendId);
        if (friend != null) {
          loadedPlayers.add(friend);
        }
      }
      return loadedPlayers;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to load friends: ${e.message}');
      throw DatabaseConnectionError('Failed to load friends: ${e.message}');
    }
  }

  static Future<Player?> _getReservedPlayer(
      String kind, String normalizedValue) async {
    final reservationId = kind == 'email'
        ? ContactIdentity.reservationIdForEmail(normalizedValue)
        : ContactIdentity.reservationIdForPhoneNumber(normalizedValue);
    final reservation = await _safeGetDocument(DatabaseConnection.client
        .collection('player_contacts')
        .doc(reservationId));
    if (!reservation.exists) {
      return null;
    }

    final playerId = reservation.data()?['player_id'];
    if (playerId is! String) {
      return null;
    }
    return fetchPlayerFromDatabase(playerId);
  }

  static List<_PlayerContactReservation> _contactReservationsForPlayer(
      Player player) {
    final reservations = <_PlayerContactReservation>[];
    if (player.normalizedEmail != null) {
      reservations.add(
        _PlayerContactReservation(
          ref: DatabaseConnection.client.collection('player_contacts').doc(
              ContactIdentity.reservationIdForEmail(player.normalizedEmail!)),
          data: {
            'kind': 'email',
            'normalized_value': player.normalizedEmail,
            'player_id': player.id,
            'created_by_uid': player.ownerId,
          },
        ),
      );
    }
    if (player.normalizedPhoneNumber != null) {
      reservations.add(
        _PlayerContactReservation(
          ref: DatabaseConnection.client.collection('player_contacts').doc(
              ContactIdentity.reservationIdForPhoneNumber(
                  player.normalizedPhoneNumber!)),
          data: {
            'kind': 'phone',
            'normalized_value': player.normalizedPhoneNumber,
            'player_id': player.id,
            'created_by_uid': player.ownerId,
          },
        ),
      );
    }
    return reservations;
  }
}

class _PlayerContactReservation {
  _PlayerContactReservation({required this.ref, required this.data});

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}

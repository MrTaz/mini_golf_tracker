import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/player.dart';

void main() {
  group('Player constructor', () {
    test('creates with required fields', () {
      final player = Player(
        id: 'p1',
        playerName: 'Alice',
        nickname: 'Ace',
        ownerId: 'owner-1',
        totalScore: 0,
      );
      expect(player.id, 'p1');
      expect(player.playerName, 'Alice');
      expect(player.nickname, 'Ace');
      expect(player.ownerId, 'owner-1');
      expect(player.totalScore, 0);
      expect(player.email, isNull);
      expect(player.phoneNumber, isNull);
      expect(player.status, isNull);
      expect(player.avatarImageLocation, isNull);
      expect(player.piiSharingPrefs, isFalse);
    });

    test('creates with all optional fields', () {
      final player = Player(
        id: 'p2',
        playerName: 'Bob',
        nickname: 'Bobby',
        ownerId: 'owner-2',
        totalScore: 100,
        email: 'bob@example.com',
        phoneNumber: '555-1234',
        normalizedEmail: 'bob@example.com',
        normalizedPhoneNumber: '5551234',
        status: 'active',
        claimedByUid: 'uid-2',
        piiSharingPrefs: true,
        avatarImageLocation: 'https://example.com/avatar.png',
      );
      expect(player.email, 'bob@example.com');
      expect(player.phoneNumber, '555-1234');
      expect(player.normalizedEmail, 'bob@example.com');
      expect(player.normalizedPhoneNumber, '5551234');
      expect(player.status, 'active');
      expect(player.claimedByUid, 'uid-2');
      expect(player.piiSharingPrefs, isTrue);
      expect(player.avatarImageLocation, 'https://example.com/avatar.png');
    });
  });

  group('Player.empty', () {
    test('creates player with empty/default values', () {
      final player = Player.empty();
      expect(player.id, '');
      expect(player.playerName, '');
      expect(player.nickname, '');
      expect(player.ownerId, '');
      expect(player.totalScore, 0);
    });
  });

  group('Player.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'p1',
        'player_name': 'Carol',
        'nickname': 'Caz',
        'owner_id': 'o1',
        'email': 'carol@example.com',
        'phone_number': '555-5678',
        'normalized_email': 'carol@example.com',
        'normalized_phone_number': '5555678',
        'status': 'active',
        'claimed_by_uid': 'uid-1',
        'pii_sharing_prefs': true,
        'total_score': 75,
        'avatar_image_location': 'https://example.com/carol.png',
      };
      final player = Player.fromJson(json);
      expect(player.id, 'p1');
      expect(player.playerName, 'Carol');
      expect(player.nickname, 'Caz');
      expect(player.ownerId, 'o1');
      expect(player.email, 'carol@example.com');
      expect(player.phoneNumber, '555-5678');
      expect(player.normalizedEmail, 'carol@example.com');
      expect(player.normalizedPhoneNumber, '5555678');
      expect(player.status, 'active');
      expect(player.claimedByUid, 'uid-1');
      expect(player.piiSharingPrefs, isTrue);
      expect(player.totalScore, 75);
      expect(player.avatarImageLocation, 'https://example.com/carol.png');
    });

    test('defaults empty string when optional fields are missing', () {
      final json = {
        'player_name': 'Dave',
        'nickname': 'D',
        'owner_id': 'o2',
        'total_score': 0,
      };
      final player = Player.fromJson(json);
      expect(player.id, '');
      expect(player.email, isNull);
      expect(player.phoneNumber, isNull);
      expect(player.status, isNull);
      expect(player.avatarImageLocation, isNull);
      expect(player.piiSharingPrefs, isFalse);
    });
  });

  group('Player.toJson', () {
    test('serializes all fields', () {
      final player = Player(
        id: 'p1',
        playerName: 'Eve',
        nickname: 'Evie',
        ownerId: 'o1',
        totalScore: 50,
        email: 'eve@example.com',
        phoneNumber: '555-9999',
        normalizedEmail: 'eve@example.com',
        normalizedPhoneNumber: '5559999',
        status: 'active',
        claimedByUid: 'uid-1',
        piiSharingPrefs: true,
        avatarImageLocation: 'https://example.com/eve.png',
      );
      final json = player.toJson();
      expect(json['id'], 'p1');
      expect(json['player_name'], 'Eve');
      expect(json['nickname'], 'Evie');
      expect(json['owner_id'], 'o1');
      expect(json['total_score'], 50);
      expect(json['email'], 'eve@example.com');
      expect(json['phone_number'], '555-9999');
      expect(json['normalized_email'], 'eve@example.com');
      expect(json['normalized_phone_number'], '5559999');
      expect(json['status'], 'active');
      expect(json['claimed_by_uid'], 'uid-1');
      expect(json['pii_sharing_prefs'], isTrue);
      expect(json['avatar_image_location'], 'https://example.com/eve.png');
    });

    test('round-trip fromJson -> toJson preserves data', () {
      final original = {
        'id': 'rt1',
        'player_name': 'Frank',
        'nickname': 'Frankie',
        'owner_id': 'o-rt',
        'email': 'frank@example.com',
        'phone_number': null,
        'status': null,
        'total_score': 20,
        'avatar_image_location': null,
      };
      final player = Player.fromJson(original);
      final result = player.toJson();
      expect(result['id'], 'rt1');
      expect(result['player_name'], 'Frank');
      expect(result['total_score'], 20);
    });
  });

  group('Player friends management', () {
    late Player owner;

    setUp(() {
      Player.players = []; // Reset static list
      owner = Player(
        id: 'owner-1',
        playerName: 'Owner',
        nickname: 'O',
        ownerId: 'owner-1',
        totalScore: 0,
      );
    });

    tearDown(() {
      Player.players = []; // Cleanup
    });

    test('getAllPlayerFriends returns empty list initially', () {
      expect(owner.getAllPlayerFriends(), isEmpty);
    });

    test('getPlayerFriendById returns empty player when not found', () {
      final result = owner.getPlayerFriendById('nonexistent');
      expect(result, isNotNull);
      expect(result?.id, '');
    });

    test('getPlayerFriendByEmail returns empty player when not found', () {
      final result = owner.getPlayerFriendByEmail('nobody@example.com');
      expect(result, isNotNull);
      expect(result?.playerName, '');
    });

    test('getPlayerFriendById returns correct player when found', () {
      final friend = Player(
        id: 'f1',
        playerName: 'Friend One',
        nickname: 'F1',
        ownerId: 'owner-1',
        totalScore: 0,
      );
      Player.players.add(friend);
      final result = owner.getPlayerFriendById('f1');
      expect(result?.playerName, 'Friend One');
    });

    test('getPlayerFriendByEmail returns correct player when found', () {
      final friend = Player(
        id: 'f2',
        playerName: 'Friend Two',
        nickname: 'F2',
        ownerId: 'owner-1',
        totalScore: 0,
        email: 'f2@example.com',
      );
      Player.players.add(friend);
      final result = owner.getPlayerFriendByEmail('f2@example.com');
      expect(result?.id, 'f2');
    });

    test('getAllPlayerFriends returns all players in static list', () {
      Player.players.addAll([
        Player(
            id: 'a',
            playerName: 'A',
            nickname: 'a',
            ownerId: 'o',
            totalScore: 0),
        Player(
            id: 'b',
            playerName: 'B',
            nickname: 'b',
            ownerId: 'o',
            totalScore: 0),
      ]);
      expect(owner.getAllPlayerFriends().length, 2);
    });
  });
}

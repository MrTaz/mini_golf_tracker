import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/contact_identity.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/player.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
      expect(player.shareName, isTrue);
      expect(player.shareEmail, isTrue);
      expect(player.sharePhone, isTrue);
      expect(player.claimStatus, ClaimStatus.none);
      expect(player.verifiedEmails, isEmpty);
      expect(player.verifiedPhones, isEmpty);
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
        shareName: false,
        shareEmail: false,
        sharePhone: false,
        avatarImageLocation: 'https://example.com/avatar.png',
        claimStatus: ClaimStatus.claimed,
        verifiedEmails: const ['bob@example.com'],
        verifiedPhones: const ['555-1234'],
      );
      expect(player.email, 'bob@example.com');
      expect(player.phoneNumber, '555-1234');
      expect(player.normalizedEmail, 'bob@example.com');
      expect(player.normalizedPhoneNumber, '5551234');
      expect(player.status, 'active');
      expect(player.claimedByUid, 'uid-2');
      expect(player.shareName, isFalse);
      expect(player.shareEmail, isFalse);
      expect(player.sharePhone, isFalse);
      expect(player.avatarImageLocation, 'https://example.com/avatar.png');
      expect(player.claimStatus, ClaimStatus.claimed);
      expect(player.verifiedEmails, const ['bob@example.com']);
      expect(player.verifiedPhones, const ['555-1234']);
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
        'share_name': false,
        'share_email': false,
        'share_phone': false,
        'total_score': 75,
        'avatar_image_location': 'https://example.com/carol.png',
        'claim_status': 'claimed',
        'verified_emails': ['carol@example.com'],
        'verified_phones': ['555-5678'],
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
      expect(player.shareName, isFalse);
      expect(player.shareEmail, isFalse);
      expect(player.sharePhone, isFalse);
      expect(player.totalScore, 75);
      expect(player.avatarImageLocation, 'https://example.com/carol.png');
      expect(player.claimStatus, ClaimStatus.claimed);
      expect(player.verifiedEmails, ['carol@example.com']);
      expect(player.verifiedPhones, ['555-5678']);
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
      expect(player.shareName, isTrue);
      expect(player.shareEmail, isTrue);
      expect(player.sharePhone, isTrue);
      expect(player.claimStatus, ClaimStatus.none);
      expect(player.verifiedEmails, isEmpty);
      expect(player.verifiedPhones, isEmpty);
    });

    test('handles unknown, pendingVerification, or null claim_status', () {
      final jsonPending = {
        'player_name': 'A',
        'nickname': 'A',
        'owner_id': 'o1',
        'total_score': 0,
        'claim_status': 'pendingVerification',
      };
      final playerPending = Player.fromJson(jsonPending);
      expect(playerPending.claimStatus, ClaimStatus.pendingVerification);

      final jsonNone = {
        'player_name': 'A',
        'nickname': 'A',
        'owner_id': 'o1',
        'total_score': 0,
        'claim_status': 'none',
      };
      final playerNone = Player.fromJson(jsonNone);
      expect(playerNone.claimStatus, ClaimStatus.none);

      final jsonUnknown = {
        'player_name': 'B',
        'nickname': 'B',
        'owner_id': 'o1',
        'total_score': 0,
        'claim_status': 'garbage_value',
      };
      final playerUnknown = Player.fromJson(jsonUnknown);
      expect(playerUnknown.claimStatus, ClaimStatus.none);

      final jsonNull = {
        'player_name': 'C',
        'nickname': 'C',
        'owner_id': 'o1',
        'total_score': 0,
        'claim_status': null,
      };
      final playerNull = Player.fromJson(jsonNull);
      expect(playerNull.claimStatus, ClaimStatus.none);
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
        shareName: false,
        shareEmail: false,
        sharePhone: false,
        avatarImageLocation: 'https://example.com/eve.png',
        claimStatus: ClaimStatus.pendingVerification,
        verifiedEmails: const ['eve@example.com'],
        verifiedPhones: const ['555-9999'],
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
      expect(json['share_name'], isFalse);
      expect(json['share_email'], isFalse);
      expect(json['share_phone'], isFalse);
      expect(json['avatar_image_location'], 'https://example.com/eve.png');
      expect(json['claim_status'], 'pendingVerification');
      expect(json['verified_emails'], ['eve@example.com']);
      expect(json['verified_phones'], ['555-9999']);
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
        'share_name': false,
        'share_email': false,
        'share_phone': false,
        'total_score': 20,
        'avatar_image_location': null,
        'claim_status': 'claimed',
        'verified_emails': ['frank@example.com'],
        'verified_phones': <String>[],
      };
      final player = Player.fromJson(original);
      final result = player.toJson();
      expect(result['id'], 'rt1');
      expect(result['player_name'], 'Frank');
      expect(result['total_score'], 20);
      expect(result['share_name'], isFalse);
      expect(result['share_email'], isFalse);
      expect(result['share_phone'], isFalse);
      expect(result['claim_status'], 'claimed');
      expect(result['verified_emails'], ['frank@example.com']);
      expect(result['verified_phones'], <String>[]);
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

  group('Player.createPlayer behavioral tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    tearDown(() {
      DatabaseConnection.setFirestoreInstanceForTesting(null);
    });

    test('verifies nickname-only creation (empty playerName)', () async {
      final player = await Player.createPlayer('', 'NickOnly', ownerId: 'owner1');
      expect(player.playerName, '');
      expect(player.nickname, 'NickOnly');
      expect(player.ownerId, 'owner1');

      final doc = await fakeFirestore.collection('players').doc(player.id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['player_name'], '');
      expect(doc.data()?['nickname'], 'NickOnly');
    });
  });

  group('Security Guardrail Tests (Phase 5.1 & Phase 5.2)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    tearDown(() {
      DatabaseConnection.setFirestoreInstanceForTesting(null);
    });

    test('resolveCanonicalPlayer throws Contact Conflict for split-identity', () async {
      // Player A has email, Player B has phone number
      await Player.createPlayer(
        'Player A',
        'PA',
        email: 'a@example.com',
        ownerId: 'owner-a',
      );
      await Player.createPlayer(
        'Player B',
        'PB',
        phoneNumber: '+15551112222',
        ownerId: 'owner-b',
      );

      final splitPlayer = Player(
        id: 'split',
        playerName: 'Split Player',
        nickname: 'Split',
        ownerId: 'owner-split',
        totalScore: 0,
        email: 'a@example.com',
        phoneNumber: '+15551112222',
      );

      expect(
        () => Player.resolveCanonicalPlayer(splitPlayer, ownerIdForNewPlayer: 'owner-new'),
        throwsA(isA<DatabaseConnectionError>().having((e) => e.message, 'message', 'Contact Conflict')),
      );
    });

    test('claimPlayerForVerifiedAuthUser and claimPlayerForAuthUser throw Contact Conflict for split-identity', () async {
      await Player.createPlayer(
        'Player A',
        'PA',
        email: 'a@example.com',
        ownerId: 'owner-a',
      );
      await Player.createPlayer(
        'Player B',
        'PB',
        phoneNumber: '+15551112222',
        ownerId: 'owner-b',
      );

      expect(
        () => Player.claimPlayerForVerifiedAuthUser(
          uid: 'uid-new',
          email: 'a@example.com',
          emailVerified: true,
          phoneNumber: '+15551112222',
        ),
        throwsA(isA<DatabaseConnectionError>().having((e) => e.message, 'message', 'Contact Conflict')),
      );

      expect(
        () => Player.claimPlayerForAuthUser(
          uid: 'uid-new',
          email: 'a@example.com',
          phoneNumber: '+15551112222',
          playerName: 'New Player',
          nickname: 'New',
        ),
        throwsA(isA<DatabaseConnectionError>().having((e) => e.message, 'message', 'Contact Conflict')),
      );
    });

    test('canVerifiedAuthUserClaimPlayer returns false for already claimed player by different UID', () async {
      final claimedPlayer = Player(
        id: 'p-claimed',
        playerName: 'Claimed',
        nickname: 'C',
        ownerId: 'owner-c',
        totalScore: 0,
        email: 'claimed@example.com',
        normalizedEmail: 'claimed@example.com',
        claimedByUid: 'uid-first',
      );

      final result = Player.canVerifiedAuthUserClaimPlayer(
        player: claimedPlayer,
        uid: 'uid-second',
        email: 'claimed@example.com',
        emailVerified: true,
        phoneNumber: null,
      );

      expect(result, isFalse);
    });

    test('canVerifiedAuthUserClaimPlayer returns true if claimed_by_uid matches current uid', () async {
      final claimedPlayer = Player(
        id: 'p-claimed',
        playerName: 'Claimed',
        nickname: 'C',
        ownerId: 'owner-c',
        totalScore: 0,
        email: 'claimed@example.com',
        normalizedEmail: 'claimed@example.com',
        claimedByUid: 'uid-first',
      );

      final result = Player.canVerifiedAuthUserClaimPlayer(
        player: claimedPlayer,
        uid: 'uid-first',
        email: 'claimed@example.com',
        emailVerified: true,
        phoneNumber: null,
      );

      expect(result, isTrue);
    });

    test('claimPlayerForVerifiedAuthUser rejects claim for already claimed player by different UID', () async {
      await Player.createPlayer(
        'Claimed Player',
        'CP',
        email: 'claimed@example.com',
        id: 'p-claimed',
        ownerId: 'owner-c',
      );
      
      // Manually set claimed_by_uid in DB
      await fakeFirestore
          .collection('players')
          .doc('p-claimed')
          .update({'claimed_by_uid': 'uid-first'});

      final result = await Player.claimPlayerForVerifiedAuthUser(
        uid: 'uid-second',
        email: 'claimed@example.com',
        emailVerified: true,
        phoneNumber: null,
      );

      expect(result, isNull);
    });

    test('claimPlayerForAuthUser throws error for already claimed player by different UID', () async {
      await Player.createPlayer(
        'Claimed Player',
        'CP',
        email: 'claimed@example.com',
        id: 'p-claimed',
        ownerId: 'owner-c',
      );

      // Manually set claimed_by_uid in DB
      await fakeFirestore
          .collection('players')
          .doc('p-claimed')
          .update({'claimed_by_uid': 'uid-first'});

      expect(
        () => Player.claimPlayerForAuthUser(
          uid: 'uid-second',
          email: 'claimed@example.com',
          playerName: 'CP',
          nickname: 'CP',
        ),
        throwsA(isA<DatabaseConnectionError>().having((e) => e.message, 'message', 'Player already claimed')),
      );
    });

    test('claimPlayerForVerifiedAuthUser returns null when canVerifiedAuthUserClaimPlayer returns false due to contact mismatch', () async {
      // Create a reservation that points to a player with a different email
      final reservationId = ContactIdentity.reservationIdForEmail('a@example.com');
      await fakeFirestore.collection('player_contacts').doc(reservationId).set({
        'kind': 'email',
        'normalized_value': 'a@example.com',
        'player_id': 'p-mismatch',
        'created_by_uid': 'owner-1',
      });

      // The player record has a completely different email
      await fakeFirestore.collection('players').doc('p-mismatch').set({
        'id': 'p-mismatch',
        'player_name': 'Mismatch Player',
        'nickname': 'Mismatch',
        'owner_id': 'owner-1',
        'total_score': 0,
        'email': 'different@example.com',
        'normalized_email': 'different@example.com',
      });

      final result = await Player.claimPlayerForVerifiedAuthUser(
        uid: 'uid-new',
        email: 'a@example.com',
        emailVerified: true,
        phoneNumber: null,
      );

      expect(result, isNull);
    });
  });

  group('Player isQuickPlay unit tests', () {
    test('creates with isQuickPlay default false', () {
      final player = Player(
        id: 'qp-test-1',
        playerName: 'Quick',
        nickname: 'Q',
        ownerId: 'owner-1',
        totalScore: 0,
      );
      expect(player.isQuickPlay, isFalse);
    });

    test('fromJson and toJson handles isQuickPlay correctly', () {
      final json = {
        'id': 'qp-test-2',
        'player_name': 'Quick 2',
        'nickname': 'Q2',
        'owner_id': 'owner-2',
        'total_score': 0,
        'is_quick_play': true,
      };
      final player = Player.fromJson(json);
      expect(player.isQuickPlay, isTrue);

      final outJson = player.toJson();
      expect(outJson['is_quick_play'], isTrue);
    });

    test('createPlayer sets isQuickPlay and resolves canonical player', () async {
      final db = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(db);

      final created = await Player.createPlayer('QP Player', 'QP', isQuickPlay: true);
      expect(created.isQuickPlay, isTrue);

      final resolved = await Player.resolveCanonicalPlayer(created, ownerIdForNewPlayer: 'owner-x');
      expect(resolved.isQuickPlay, isTrue);

      DatabaseConnection.setFirestoreInstanceForTesting(null);
    });
  });

  group('Player createPlayer ownerId defaults coverage tests', () {
    test('createPlayer with active Firebase apps and matching currentUser UID', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final originalFirebase = FirebasePlatform.instance;
      final originalAuth = FirebaseAuthPlatform.instance;

      try {
        setupFirebaseCoreMocks();
        await Firebase.initializeApp();

        final mockUser = MyMockUserPlatform(
          uid: 'auth-user-uid',
          email: 'test@example.com',
        );
        MockFirebaseAuthPlatform.mockUser = mockUser;
        MockFirebaseAuthPlatform.shouldThrow = false;
        FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();

        final testFirestore = FakeFirebaseFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

        final player = await Player.createPlayer('Test Player', 'TP');
        expect(player.ownerId, 'auth-user-uid');
      } finally {
        FirebasePlatform.instance = originalFirebase;
        FirebaseAuthPlatform.instance = originalAuth;
        DatabaseConnection.setFirestoreInstanceForTesting(null);
      }
    });

    test('createPlayer when auth currentUser getter throws exception defaults to guest', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final originalFirebase = FirebasePlatform.instance;
      final originalAuth = FirebaseAuthPlatform.instance;

      try {
        setupFirebaseCoreMocks();
        await Firebase.initializeApp();

        MockFirebaseAuthPlatform.mockUser = null;
        MockFirebaseAuthPlatform.shouldThrow = true;
        FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();

        final testFirestore = FakeFirebaseFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

        final player = await Player.createPlayer('Test Player', 'TP');
        expect(player.ownerId, 'guest');
      } finally {
        FirebasePlatform.instance = originalFirebase;
        FirebaseAuthPlatform.instance = originalAuth;
        DatabaseConnection.setFirestoreInstanceForTesting(null);
      }
    });
  });
}

class MockFirebasePlatform extends FirebasePlatform {
  final bool shouldThrow;
  MockFirebasePlatform({this.shouldThrow = false}) : super();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      options ??
          const FirebaseOptions(
            apiKey: 'key',
            appId: 'id',
            messagingSenderId: 'sender',
            projectId: 'project',
          ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps => [
        FirebaseAppPlatform(
            '[DEFAULT]',
            const FirebaseOptions(
              apiKey: 'key',
              appId: 'id',
              messagingSenderId: 'sender',
              projectId: 'project',
            ))
      ];

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    if (shouldThrow) {
      throw Exception('Simulated Firebase Platform Exception');
    }
    return apps.first;
  }
}

class MyMockUserPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UserPlatform {
  @override
  final String uid;
  @override
  final String? email;
  final bool emailVerified;

  MyMockUserPlatform({
    required this.uid,
    this.email,
    this.emailVerified = true,
  });
}

class MockFirebaseAuthPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseAuthPlatform {
  static UserPlatform? mockUser;
  static bool shouldThrow = false;

  MockFirebaseAuthPlatform();

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    covariant dynamic currentUser,
    covariant dynamic languageCode,
  }) {
    return this;
  }

  @override
  Stream<UserPlatform?> authStateChanges() => const Stream.empty();

  @override
  Stream<UserPlatform?> userChanges() => const Stream.empty();

  @override
  Stream<UserPlatform?> idTokenChanges() => const Stream.empty();

  @override
  UserPlatform? get currentUser {
    if (shouldThrow) {
      throw Exception('Simulated Auth Exception');
    }
    return mockUser;
  }
}

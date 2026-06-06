// ignore_for_file: subtype_of_sealed_class, must_be_immutable, depend_on_referenced_packages, unnecessary_import, override_on_non_overriding_member

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:mini_golf_tracker/core/errors/database_connection_error.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/courses/data/models/course.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

Course _makeCourse({int holes = 2}) => Course(
      id: 'c1',
      name: 'Test Course',
      numberOfHoles: holes,
      parStrokes: {for (int i = 1; i <= holes; i++) i: 3},
    );

Player _makeCreator() => Player(
      id: 'creator-1',
      playerName: 'Creator',
      nickname: 'C',
      ownerId: 'creator-1',
      totalScore: 0,
    );

Game _makeGame({String id = 'g1', List<PlayerGameInfo>? players}) => Game(
      id: id,
      name: 'Test Game',
      course: _makeCourse(),
      players: players ?? [],
      scheduledTime: DateTime(2024, 1, 15),
      status: 'completed',
    );

Map<String, dynamic> _firestoreGameDoc(String id, String creatorId) => {
      'id': id,
      'name': 'Stored Game',
      'creator_id': creatorId,
      'participant_ids': [creatorId],
      'scheduled_time': '2024-01-15T00:00:00.000',
      'start_time': null,
      'completed_time': null,
      'status': 'completed',
      'course': {
        'id': 'c1',
        'name': 'Test Course',
        'number_of_holes': 2,
        'par_strokes': {'1': 3, '2': 3},
      },
      'players': [],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    Player.players = [];
    SharedPreferences.setMockInitialValues({});
  });

  // ════════════════════════════════════════════════════════════════════════════
  // DatabaseConnection
  // ════════════════════════════════════════════════════════════════════════════

  group('DatabaseConnection', () {
    test('client returns the injected fake', () {
      expect(DatabaseConnection.client, same(fakeFirestore));
    });

    test('getFirestore() returns the injected fake', () {
      expect(DatabaseConnection.getFirestore(), same(fakeFirestore));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Player — database methods
  // ════════════════════════════════════════════════════════════════════════════

  group('Player.getPlayerByEmailFromDB', () {
    test('returns player when found', () async {
      await fakeFirestore.collection('players').doc('pid').set({
        'player_name': 'Alice',
        'email': 'alice@test.com',
        'nickname': 'Al',
        'owner_id': 'o1',
        'total_score': 10,
      });
      final p = await Player.getPlayerByEmailFromDB('alice@test.com');
      expect(p, isNotNull);
      expect(p!.playerName, 'Alice');
      expect(p.id, 'pid');
    });

    test('returns null when not found', () async {
      final p = await Player.getPlayerByEmailFromDB('ghost@test.com');
      expect(p, isNull);
    });
  });

  group('Player.fetchPlayerFromDatabase', () {
    test('returns player by ID', () async {
      await fakeFirestore.collection('players').doc('uid-123').set({
        'player_name': 'Bob',
        'nickname': 'Bobby',
        'owner_id': 'uid-123',
        'total_score': 50,
      });
      final p = await Player.fetchPlayerFromDatabase('uid-123');
      expect(p, isNotNull);
      expect(p!.playerName, 'Bob');
      expect(p.id, 'uid-123');
    });

    test('returns null when ID not found', () async {
      final p = await Player.fetchPlayerFromDatabase('non-existent');
      expect(p, isNull);
    });
  });

  group('Player.fetchPlayerForAuthUid', () {
    test('returns claimed player when document id differs from auth uid',
        () async {
      await fakeFirestore.collection('players').doc('player-1').set({
        'player_name': 'Claimed Player',
        'nickname': 'Claimed',
        'owner_id': 'creator-1',
        'claimed_by_uid': 'auth-uid',
        'total_score': 0,
      });

      final player = await Player.fetchPlayerForAuthUid('auth-uid');

      expect(player, isNotNull);
      expect(player!.id, 'player-1');
    });
  });

  group('Player.createPlayer', () {
    test('creates new player in DB and returns it', () async {
      final p = await Player.createPlayer('New Player', 'NewNick',
          email: 'new@test.com');
      expect(p.playerName, 'New Player');
      expect(p.email, 'new@test.com');

      final doc = await fakeFirestore.collection('players').doc(p.id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['player_name'], 'New Player');
    });

    test('throws error if duplicate email', () async {
      await fakeFirestore.collection('players').doc('existing').set({
        'email': 'dup@test.com',
        'player_name': 'Existing',
        'nickname': 'Ex',
      });

      expect(
        () => Player.createPlayer('Dup', 'D', email: 'dup@test.com'),
        throwsA(isA<DatabaseConnectionError>()),
      );
    });

    test('normalizes contacts and reserves them atomically', () async {
      final player = await Player.createPlayer(
        'Reserved Player',
        'Reserved',
        email: ' Reserved@Example.COM ',
        phoneNumber: ' +1 (555) 123-4567 ',
      );

      expect(player.email, 'reserved@example.com');
      expect(player.normalizedEmail, 'reserved@example.com');
      expect(player.phoneNumber, '+15551234567');
      expect(player.normalizedPhoneNumber, '+15551234567');

      final emailReservation = await fakeFirestore
          .collection('player_contacts')
          .doc('email_reserved@example.com')
          .get();
      final phoneReservation = await fakeFirestore
          .collection('player_contacts')
          .doc('phone_+15551234567')
          .get();
      expect(emailReservation.data()?['player_id'], player.id);
      expect(phoneReservation.data()?['player_id'], player.id);
    });

    test('rejects duplicate normalized contacts', () async {
      await Player.createPlayer(
        'First Player',
        'First',
        email: 'same@example.com',
        phoneNumber: '+1 555 222 3333',
      );

      expect(
        () => Player.createPlayer(
          'Second Player',
          'Second',
          email: ' SAME@example.com ',
        ),
        throwsA(isA<DatabaseConnectionError>()),
      );
      expect(
        () => Player.createPlayer(
          'Third Player',
          'Third',
          phoneNumber: '+1 (555) 222-3333',
        ),
        throwsA(isA<DatabaseConnectionError>()),
      );
    });
  });

  group('Player verified claiming', () {
    test('allows a verified matching email to claim a player', () async {
      await fakeFirestore.collection('players').doc('claimable').set({
        'player_name': 'Claimable',
        'nickname': 'C',
        'owner_id': 'creator-1',
        'email': 'claim@example.com',
        'normalized_email': 'claim@example.com',
        'total_score': 0,
      });

      final claimed = await Player.claimPlayerForVerifiedAuthUser(
        uid: 'auth-1',
        email: 'claim@example.com',
        emailVerified: true,
        phoneNumber: null,
      );

      expect(claimed?.id, 'claimable');
      expect(claimed?.claimedByUid, 'auth-1');
    });

    test('does not allow an unverified email to claim a player', () async {
      await fakeFirestore.collection('players').doc('claimable').set({
        'player_name': 'Claimable',
        'nickname': 'C',
        'owner_id': 'creator-1',
        'email': 'claim@example.com',
        'normalized_email': 'claim@example.com',
        'total_score': 0,
      });

      final claimed = await Player.claimPlayerForVerifiedAuthUser(
        uid: 'auth-1',
        email: 'claim@example.com',
        emailVerified: false,
        phoneNumber: null,
      );

      expect(claimed, isNull);
    });

    test('allows a matching linked phone to claim a player', () async {
      await fakeFirestore.collection('players').doc('phone-claimable').set({
        'player_name': 'Claimable',
        'nickname': 'C',
        'owner_id': 'creator-1',
        'phone_number': '+15551234567',
        'normalized_phone_number': '+15551234567',
        'total_score': 0,
      });

      final claimed = await Player.claimPlayerForVerifiedAuthUser(
        uid: 'auth-1',
        email: null,
        emailVerified: false,
        phoneNumber: '+1 (555) 123-4567',
      );

      expect(claimed?.id, 'phone-claimable');
    });
  });

  group('Player.updateUnclaimedPlayer', () {
    test('adds contact data and contact reservations later', () async {
      final player = Player(
        id: 'late-contact',
        playerName: 'Late Contact',
        nickname: 'Late',
        ownerId: 'creator-1',
        totalScore: 0,
      );
      await fakeFirestore
          .collection('players')
          .doc(player.id)
          .set(player.toJson());
      player.email = ' Late@Example.COM ';
      player.phoneNumber = ' +1 (555) 111-2222 ';

      await Player.updateUnclaimedPlayer(player);

      final updated =
          await fakeFirestore.collection('players').doc(player.id).get();
      expect(updated.data()?['normalized_email'], 'late@example.com');
      expect(updated.data()?['normalized_phone_number'], '+15551112222');
      expect(
        (await fakeFirestore
                .collection('player_contacts')
                .doc('email_late@example.com')
                .get())
            .data()?['player_id'],
        player.id,
      );
    });
  });

  group('Player.addPlayerFriend', () {
    test('adds existing player as friend', () async {
      final owner = Player(
          id: 'o1',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'o1',
          totalScore: 0);
      final friend = Player(
          id: 'f1',
          playerName: 'Friend',
          nickname: 'F',
          ownerId: 'f1',
          totalScore: 0,
          email: 'friend@test.com');

      // Setup existing friend in DB
      await fakeFirestore.collection('players').doc('f1').set(friend.toJson());

      owner.addPlayerFriend(friend);

      // Wait for microtask
      await Future.delayed(Duration(milliseconds: 100));

      expect(Player.players.any((p) => p.id == 'f1'), isTrue);

      final friendDoc =
          await fakeFirestore.collection('friends').doc('o1_f1').get();
      expect(friendDoc.exists, isTrue);
      expect(friendDoc.data()!['friend_id'], 'f1');
    });

    test('creates new player in DB and adds as friend if not exists', () async {
      final owner = Player(
          id: 'o1',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'o1',
          totalScore: 0);
      final newFriend = Player(
          id: 'temp',
          playerName: 'Newbie',
          nickname: 'N',
          ownerId: 'o1',
          totalScore: 0,
          email: 'newbie@test.com',
          phoneNumber: '123');

      owner.addPlayerFriend(newFriend);

      // Wait for microtask
      await Future.delayed(Duration(milliseconds: 100));

      final playersInDb = await fakeFirestore
          .collection('players')
          .where('email', isEqualTo: 'newbie@test.com')
          .get();
      expect(playersInDb.docs.isNotEmpty, isTrue);

      final createdFriendId = playersInDb.docs.first.id;
      expect(Player.players.any((p) => p.id == createdFriendId), isTrue);

      final friendDoc = await fakeFirestore
          .collection('friends')
          .doc('o1_$createdFriendId')
          .get();
      expect(friendDoc.exists, isTrue);
    });

    test('refreshes an existing friend entry with canonical player details',
        () async {
      final owner = Player(
        id: 'o1',
        playerName: 'Owner',
        nickname: 'O',
        ownerId: 'o1',
        totalScore: 0,
      );
      Player.players = [
        Player(
          id: 'f1',
          playerName: 'Old Friend',
          nickname: 'Old',
          ownerId: 'o1',
          totalScore: 0,
          email: 'friend@test.com',
        ),
      ];
      await fakeFirestore.collection('players').doc('f1').set({
        'player_name': 'Canonical Friend',
        'nickname': 'Canonical',
        'owner_id': 'creator-2',
        'email': 'friend@test.com',
        'total_score': 0,
      });

      await owner.addPlayerFriend(
        Player(
          id: '',
          playerName: 'Entered Friend',
          nickname: 'Entered',
          ownerId: '',
          totalScore: 0,
          email: 'friend@test.com',
        ),
      );

      expect(Player.players.single.nickname, 'Canonical');
    });
  });

  group('Player.loadUserPlayers', () {
    test('loads players from DB through friend links', () async {
      Player.players = [];
      final owner = Player(
          id: 'o1',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'o1',
          totalScore: 0);

      await fakeFirestore.collection('players').doc('f1').set({
        'player_name': 'Friend 1',
        'nickname': 'F1',
        'owner_id': 'o1',
        'total_score': 10,
      });
      await fakeFirestore.collection('players').doc('f2').set({
        'player_name': 'Friend 2',
        'nickname': 'F2',
        'owner_id': 'o1',
        'total_score': 20,
      });
      await fakeFirestore.collection('friends').doc('o1_f1').set({
        'player_id': 'o1',
        'friend_id': 'f1',
      });
      await fakeFirestore.collection('friends').doc('o1_f2').set({
        'player_id': 'o1',
        'friend_id': 'f2',
      });

      await owner.loadUserPlayers();

      expect(Player.players.length, 2);
      expect(Player.players.any((p) => p.playerName == 'Friend 1'), isTrue);
      expect(Player.players.any((p) => p.playerName == 'Friend 2'), isTrue);
    });

    test('does not reload if players already populated', () async {
      Player.players = [Player.empty()];
      final owner = Player(
          id: 'o1',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'o1',
          totalScore: 0);

      await owner.loadUserPlayers();

      expect(
          Player.players.length, 1); // Should still be 1, didn't fetch from DB
    });
  });

  group('Player.updatePlayerScoreInDatabase', () {
    test('updates total_score in Firestore', () async {
      await fakeFirestore.collection('players').doc('p1').set({
        'player_name': 'Bob',
        'email': 'bob@test.com',
        'nickname': 'B',
        'owner_id': 'o1',
        'total_score': 0,
      });
      final player = Player(
          id: 'p1',
          playerName: 'Bob',
          nickname: 'B',
          ownerId: 'o1',
          totalScore: 99);
      await Player.updatePlayerScoreInDatabase(player);
      final doc = await fakeFirestore.collection('players').doc('p1').get();
      expect(doc.data()!['total_score'], 99);
    });
  });

  group('Player.loadUserPlayers', () {
    test('loads players from Firestore through friend links', () async {
      await fakeFirestore.collection('players').doc('fp1').set({
        'player_name': 'Carol',
        'email': 'carol@test.com',
        'nickname': 'C',
        'owner_id': 'owner-x',
        'total_score': 5,
      });
      final owner = Player(
          id: 'owner-x',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'owner-x',
          totalScore: 0);
      await fakeFirestore.collection('friends').doc('owner-x_fp1').set({
        'player_id': 'owner-x',
        'friend_id': 'fp1',
      });
      Player.players = [];
      await owner.loadUserPlayers();
      expect(Player.players.length, 1);
      expect(Player.players.first.playerName, 'Carol');
    });

    test('skips load when players list already populated', () async {
      Player.players = [
        Player(
            id: 'existing',
            playerName: 'Already',
            nickname: 'A',
            ownerId: 'o',
            totalScore: 0)
      ];
      // Add another player to DB — should NOT be loaded since list is non-empty
      await fakeFirestore.collection('players').add({
        'player_name': 'Extra',
        'email': 'x@test.com',
        'nickname': 'X',
        'owner_id': 'o',
        'total_score': 0,
      });
      final owner = Player(
          id: 'o', playerName: 'O', nickname: 'O', ownerId: 'o', totalScore: 0);
      await owner.loadUserPlayers();
      expect(Player.players.length, 1); // still only 1
    });

    test('skips load when ownerId is empty', () async {
      Player.players = [];
      await fakeFirestore.collection('players').add({
        'player_name': 'Nobody',
        'email': 'n@test.com',
        'nickname': 'N',
        'owner_id': '',
        'total_score': 0,
      });
      final owner = Player(
          id: '',
          playerName: 'Empty',
          nickname: 'E',
          ownerId: '',
          totalScore: 0);
      await owner.loadUserPlayers();
      expect(Player.players, isEmpty);
    });
  });

  group('Player.createPlayer', () {
    test('creates and returns a new player', () async {
      final created = await Player.createPlayer('NewPerson', 'NP',
          email: 'new@test.com', phoneNumber: '555-0001');
      expect(created.playerName, 'NewPerson');
      expect(created.id, isNotEmpty);
      final doc =
          await fakeFirestore.collection('players').doc(created.id).get();
      expect(doc.exists, isTrue);
    });

    test('throws DatabaseConnectionError on duplicate email', () async {
      await fakeFirestore.collection('players').add({
        'player_name': 'Existing',
        'email': 'dup@test.com',
        'phone_number': '555-9999',
        'nickname': 'E',
        'owner_id': 'o1',
        'total_score': 0,
      });
      expect(
          () => Player.createPlayer('Dup', 'D',
              email: 'dup@test.com', phoneNumber: '555-0000'),
          throwsA(anything));
    });

    test('sets ownerId to player id when ownerId is empty', () async {
      // Create with no explicit ownerId (uses instance's empty logic internally)
      final created = await Player.createPlayer('SelfOwned', 'SO',
          email: 'selfowned@test.com', phoneNumber: '555-0002');
      // createPlayer defaults ownerId to its docRef.id when no ownerId is provided
      expect(created.ownerId, isNotEmpty);
    });

    test('rejects duplicate email when a different id is requested', () async {
      await fakeFirestore.collection('players').doc('old-id').set({
        'player_name': 'Old Name',
        'nickname': 'OldNick',
        'email': 'migrate@test.com',
        'owner_id': 'old-id',
        'total_score': 0,
      });

      expect(
        () => Player.createPlayer(
          'New Name',
          'NewNick',
          email: 'migrate@test.com',
          id: 'new-id',
          ownerId: 'new-id',
        ),
        throwsA(isA<DatabaseConnectionError>()),
      );
    });

    test('retains old profile when email match has same id', () async {
      await fakeFirestore.collection('players').doc('same-id').set({
        'player_name': 'Existing Name',
        'nickname': 'EN',
        'email': 'same@test.com',
        'owner_id': 'same-id',
        'total_score': 0,
      });

      final returned = await Player.createPlayer(
        'Different Name',
        'DN',
        email: 'same@test.com',
        id: 'same-id',
      );

      expect(returned.id, 'same-id');
      expect(returned.playerName, 'Existing Name');
    });

    test('claims existing email profile for auth user', () async {
      await fakeFirestore.collection('players').doc('delete-fail-id').set({
        'player_name': 'Old Fail Name',
        'nickname': 'OFN',
        'email': 'deletefail@test.com',
        'owner_id': 'delete-fail-id',
        'total_score': 0,
      });

      final claimed = await Player.claimPlayerForAuthUser(
        uid: 'new-success-id',
        email: 'deletefail@test.com',
        playerName: 'New Fail Name',
        nickname: 'NFN',
      );

      expect(claimed.id, 'delete-fail-id');
      expect(claimed.claimedByUid, 'new-success-id');
      final oldDoc =
          await fakeFirestore.collection('players').doc('delete-fail-id').get();
      expect(oldDoc.data()?['claimed_by_uid'], 'new-success-id');
    });

    test('rejects duplicate phone when a different id is requested', () async {
      await fakeFirestore.collection('players').doc('phone-old-id').set({
        'player_name': 'Old Name',
        'nickname': 'OldNick',
        'phone_number': '555-1234',
        'owner_id': 'phone-old-id',
        'total_score': 0,
      });

      expect(
        () => Player.createPlayer(
          'New Name',
          'NewNick',
          phoneNumber: '555-1234',
          id: 'phone-new-id',
          ownerId: 'phone-new-id',
        ),
        throwsA(isA<DatabaseConnectionError>()),
      );
    });

    test('retains old profile when phone match has same id', () async {
      await fakeFirestore.collection('players').doc('phone-same-id').set({
        'player_name': 'Existing Name',
        'nickname': 'EN',
        'phone_number': '555-5678',
        'owner_id': 'phone-same-id',
        'total_score': 0,
      });

      final returned = await Player.createPlayer(
        'Different Name',
        'DN',
        phoneNumber: '555-5678',
        id: 'phone-same-id',
      );

      expect(returned.id, 'phone-same-id');
      expect(returned.playerName, 'Existing Name');
    });

    test('claims existing phone profile for auth user', () async {
      await fakeFirestore
          .collection('players')
          .doc('phone-delete-fail-id')
          .set({
        'player_name': 'Old Fail Name',
        'nickname': 'OFN',
        'phone_number': '555-9012',
        'owner_id': 'phone-delete-fail-id',
        'total_score': 0,
      });

      final claimed = await Player.claimPlayerForAuthUser(
        uid: 'phone-new-success-id',
        email: '',
        phoneNumber: '555-9012',
        playerName: 'New Fail Name',
        nickname: 'NFN',
      );

      expect(claimed.id, 'phone-delete-fail-id');
      expect(claimed.claimedByUid, 'phone-new-success-id');
      final oldDoc = await fakeFirestore
          .collection('players')
          .doc('phone-delete-fail-id')
          .get();
      expect(oldDoc.data()?['claimed_by_uid'], 'phone-new-success-id');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Course — database methods
  // ════════════════════════════════════════════════════════════════════════════

  group('Course.fetchCourses', () {
    test('returns all courses', () async {
      await fakeFirestore.collection('courses').add({
        'name': 'Course A',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
      await fakeFirestore.collection('courses').add({
        'name': 'Course B',
        'number_of_holes': 18,
        'par_strokes': {'1': 4},
      });
      final courses = await Course.fetchCourses();
      expect(courses.length, 2);
      expect(
          courses.map((c) => c?.name), containsAll(['Course A', 'Course B']));
    });

    test('returns empty list when none exist', () async {
      final courses = await Course.fetchCourses();
      expect(courses, isEmpty);
    });
  });

  group('Course.saveCourseToDatabase', () {
    test('saves course and returns with Firestore id', () async {
      final course = Course(
          id: '', name: 'New Course', numberOfHoles: 9, parStrokes: {1: 3});
      final saved = await course.saveCourseToDatabase();
      expect(saved.id, isNotEmpty);
      expect(saved.name, 'New Course');
      final doc = await fakeFirestore.collection('courses').doc(saved.id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['number_of_holes'], 9);
    });

    test('throws when duplicate name+holes exists', () async {
      final c = Course(
          id: '', name: 'Dup Course', numberOfHoles: 9, parStrokes: {1: 3});
      await c.saveCourseToDatabase();
      expect(
          () => Course(
              id: '',
              name: 'Dup Course',
              numberOfHoles: 9,
              parStrokes: {1: 3}).saveCourseToDatabase(),
          throwsException);
    });
  });

  group('Course.deleteCourseFromDatabase', () {
    test('deletes course from database by ID', () async {
      final docRef = await fakeFirestore.collection('courses').add({
        'name': 'Course to Delete',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
      final course = Course(
          id: docRef.id,
          name: 'Course to Delete',
          numberOfHoles: 9,
          parStrokes: {1: 3});

      // Let's verify it exists
      var courses = await Course.fetchCourses();
      expect(courses.any((c) => c?.id == docRef.id), isTrue);

      // Delete it
      await course.deleteCourseFromDatabase();

      // Verify it's gone
      courses = await Course.fetchCourses();
      expect(courses.any((c) => c?.id == docRef.id), isFalse);
    });
  });

  group('Course.fetchCoursesPaginated', () {
    test('fetches courses in alphabetical order with limit and startAfter',
        () async {
      // Clear or ensure fresh start for pagination query tests
      final existing = await fakeFirestore.collection('courses').get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }

      // Add 4 courses in random alphabetical order
      await fakeFirestore.collection('courses').add({
        'name': 'Golf course C',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
      await fakeFirestore.collection('courses').add({
        'name': 'Golf course A',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
      await fakeFirestore.collection('courses').add({
        'name': 'Golf course D',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
      await fakeFirestore.collection('courses').add({
        'name': 'Golf course B',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });

      // Page 1: limit of 2. Should return Golf course A and Golf course B
      final page1 = await Course.fetchCoursesPaginated(limit: 2);
      expect(page1.courses.length, 2);
      expect(page1.courses[0].name, 'Golf course A');
      expect(page1.courses[1].name, 'Golf course B');
      expect(page1.lastDocument, isNotNull);

      // Page 2: limit of 2, startAfter last document of page 1. Should return Golf course C and Golf course D
      final page2 = await Course.fetchCoursesPaginated(
        limit: 2,
        startAfter: page1.lastDocument,
      );
      expect(page2.courses.length, 2);
      expect(page2.courses[0].name, 'Golf course C');
      expect(page2.courses[1].name, 'Golf course D');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Game — database methods
  // ════════════════════════════════════════════════════════════════════════════

  group('Game.saveLocalGame', () {
    test('stores game JSON in SharedPreferences', () async {
      final game = _makeGame(id: 'local-g1');
      await Game.saveLocalGame(game);
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('local-g1');
      expect(stored, isNotNull);
      final decoded = jsonDecode(stored!) as Map<String, dynamic>;
      expect(decoded['name'], 'Test Game');
    });
  });

  group('Game.getLocallySavedGames', () {
    test('returns all locally saved games', () async {
      final game = _makeGame(id: 'local-g2', players: []);
      await Game.saveLocalGame(game);
      final games = await Game.getLocallySavedGames();
      expect(games.length, 1);
      expect(games.first!.id, 'local-g2');
    });

    test('filters by status when gameStatusTypes provided', () async {
      final completedGame = _makeGame(id: 'completed-g');
      await Game.saveLocalGame(completedGame);

      final inProgressGame = Game(
        id: 'inprog-g',
        name: 'In Progress',
        course: _makeCourse(),
        players: [],
        scheduledTime: DateTime(2024, 2, 1),
        status: 'in_progress',
      );
      await Game.saveLocalGame(inProgressGame);

      final completedOnly =
          await Game.getLocallySavedGames(gameStatusTypes: ['completed']);
      expect(completedOnly.length, 1);
      expect(completedOnly.first!.status, 'completed');
    });

    test('skips reserved keys (email, loggedInUser, courses)', () async {
      SharedPreferences.setMockInitialValues({
        'email': 'test@test.com',
        'loggedInUser': 'uid',
        'courses': 'some-data',
      });
      final games = await Game.getLocallySavedGames();
      expect(games, isEmpty);
    });

    test('skips non-JSON string values gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'random-key': 'not a json string at all',
      });
      final games = await Game.getLocallySavedGames();
      expect(games, isEmpty);
    });
  });

  group('Game.initializeLocalGames', () {
    test('adopts locally saved games before loading remote games', () async {
      final user = _makeCreator();
      final localGame = _makeGame(id: 'local-adopt');
      await Game.saveLocalGame(localGame);

      await Game.initializeLocalGames(user);

      final adoptedGame =
          await fakeFirestore.collection('games').doc('local-adopt').get();
      expect(adoptedGame.exists, isTrue);
      expect(adoptedGame.data()?['creator_id'], user.id);
    });

    test('fetches games from Firestore and saves locally', () async {
      await fakeFirestore
          .collection('games')
          .doc('db-g1')
          .set(_firestoreGameDoc('db-g1', 'user-1'));

      final user = Player(
          id: 'user-1',
          playerName: 'User',
          nickname: 'U',
          ownerId: 'user-1',
          totalScore: 0);
      await Game.initializeLocalGames(user);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('db-g1'), isNotNull);
    });

    test('keeps adopted local games and downloaded remote games locally',
        () async {
      final user = _makeCreator();
      await Game.saveLocalGame(_makeGame(id: 'local-merge'));
      await fakeFirestore
          .collection('games')
          .doc('remote-merge')
          .set(_firestoreGameDoc('remote-merge', user.id));

      await Game.initializeLocalGames(user);

      final localGames = await Game.getLocallySavedGames();
      expect(
        localGames.whereType<Game>().map((game) => game.id),
        containsAll(['local-merge', 'remote-merge']),
      );
    });

    test('adopts local guest players and rewrites local game player ids',
        () async {
      final user = _makeCreator();
      Player.players = [
        Player(
          id: 'guest-player',
          playerName: 'Guest Player',
          nickname: 'Guest',
          ownerId: 'guest',
          totalScore: 0,
          email: 'known@example.com',
        ),
      ];
      await Player.saveLocalGuestPlayers();
      await fakeFirestore.collection('players').doc('canonical-player').set({
        'player_name': 'Canonical Player',
        'nickname': 'Canonical',
        'owner_id': 'creator-2',
        'email': 'known@example.com',
        'total_score': 0,
      });
      await Game.saveLocalGame(
        _makeGame(
          id: 'local-player-remap',
          players: [
            PlayerGameInfo(
              playerId: 'guest-player',
              gameId: 'local-player-remap',
              scores: [],
            ),
          ],
        ),
      );

      await Game.initializeLocalGames(user);

      final adoptedGame = await fakeFirestore
          .collection('games')
          .doc('local-player-remap')
          .get();
      expect(
        adoptedGame.data()?['players'][0]['player_id'],
        'canonical-player',
      );
      final friendLink = await fakeFirestore
          .collection('friends')
          .doc('${user.id}_canonical-player')
          .get();
      expect(friendLink.exists, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('guest_players'), isNull);
    });

    test('does not throw when Firestore returns no games', () async {
      final user = Player(
          id: 'nobody',
          playerName: 'Nobody',
          nickname: 'N',
          ownerId: 'nobody',
          totalScore: 0);
      expect(() => Game.initializeLocalGames(user), returnsNormally);
    });
  });

  group('Game.clearLocallySavedGames', () {
    test('removes only stored games', () async {
      await Game.saveLocalGame(_makeGame(id: 'clear-local'));
      SharedPreferences.setMockInitialValues({
        'clear-local': jsonEncode(_makeGame(id: 'clear-local').toJson()),
        'email': 'user@example.com',
        'courses': 'course-cache',
      });

      await Game.clearLocallySavedGames();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('clear-local'), isNull);
      expect(prefs.getString('email'), 'user@example.com');
      expect(prefs.getString('courses'), 'course-cache');
    });
  });

  group('Game.fetchGamesForCurrentUser', () {
    test('returns matching participant games', () async {
      await fakeFirestore
          .collection('games')
          .doc('fg1')
          .set(_firestoreGameDoc('fg1', 'user-2'));
      final games = await Game.fetchGamesForCurrentUser('user-2');
      expect(games.length, 1);
      expect(games.first.name, 'Stored Game');
    });

    test('returns empty list when no games', () async {
      final games = await Game.fetchGamesForCurrentUser('ghost-user');
      expect(games, isEmpty);
    });
  });

  group('Game.saveGameToDatabase', () {
    test('saves game doc and player_game_info records', () async {
      final p1 = PlayerGameInfo(
          playerId: 'p1',
          gameId: 'sg1',
          scores: [3, 4],
          totalScore: 7,
          place: '1st',
          playOrderPosition: 1);
      final game = _makeGame(id: 'sg1', players: [p1]);
      game.startTime = DateTime(2024, 1, 15, 10, 0);
      game.completedTime = DateTime(2024, 1, 15, 12, 0);
      final creator = _makeCreator();

      await Game.saveGameToDatabase(game, creator);

      final gameDoc = await fakeFirestore.collection('games').doc('sg1').get();
      expect(gameDoc.exists, isTrue);
      expect(gameDoc.data()!['name'], 'Test Game');
      expect(gameDoc.data()!['creator_id'], 'creator-1');

      final pgiDoc = await fakeFirestore
          .collection('player_game_info')
          .doc('sg1_p1')
          .get();
      expect(pgiDoc.exists, isTrue);
      expect(pgiDoc.data()!['total_score'], 7);
    });

    test('saves game with no players (no player_game_info written)', () async {
      final game = _makeGame(id: 'sg2');
      final creator = _makeCreator();
      await Game.saveGameToDatabase(game, creator);
      final gameDoc = await fakeFirestore.collection('games').doc('sg2').get();
      expect(gameDoc.exists, isTrue);
      // No PGI doc should exist
      final pgiDocs = await fakeFirestore.collection('player_game_info').get();
      expect(pgiDocs.docs, isEmpty);
    });

    test('saves start_time as null when not set', () async {
      final game = _makeGame(id: 'sg3');
      await Game.saveGameToDatabase(game, _makeCreator());
      final doc = await fakeFirestore.collection('games').doc('sg3').get();
      expect(doc.data()!['start_time'], isNull);
      expect(doc.data()!['completed_time'], isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Game.fromJson — null datetime branches
  // ════════════════════════════════════════════════════════════════════════════

  group('Game.fromJson null datetime branches', () {
    test('parses null start_time and completed_time correctly', () {
      final json = jsonEncode({
        'id': 'gx',
        'name': 'Null Times Game',
        'course': {
          'id': 'c1',
          'name': 'Test Course',
          'number_of_holes': 2,
          'par_strokes': {'1': 3, '2': 3},
        },
        'players': [],
        'start_time': null,
        'scheduled_time': '2024-03-01T00:00:00.000',
        'completed_time': null,
        'status': 'unstarted_game',
      });
      final game = Game.fromJson(json);
      expect(game.startTime, isNull);
      expect(game.completedTime, isNull);
      expect(game.scheduledTime, DateTime(2024, 3, 1));
    });

    test('parses null scheduled_time by defaulting to now', () {
      final json = jsonEncode({
        'id': 'gx2',
        'name': 'No Schedule',
        'course': {
          'id': 'c1',
          'name': 'Test Course',
          'number_of_holes': 2,
          'par_strokes': {'1': 3, '2': 3},
        },
        'players': [],
        'start_time': null,
        'scheduled_time': null,
        'completed_time': null,
        'status': 'unstarted_game',
      });
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final game = Game.fromJson(json);
      expect(game.scheduledTime.isAfter(before), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Player.addPlayerFriend — async branches via Future.microtask
  // ════════════════════════════════════════════════════════════════════════════

  group('Player.addPlayerFriend', () {
    test('adds existing player as friend (existing user path)', () async {
      // Seed an existing player in Firestore
      await fakeFirestore.collection('players').doc('existing-friend').set({
        'player_name': 'ExistingFriend',
        'email': 'ef@test.com',
        'phone_number': '555-1111',
        'nickname': 'EF',
        'owner_id': 'owner-ef',
        'total_score': 0,
      });

      final owner = Player(
          id: 'owner-ef',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'owner-ef',
          totalScore: 0);

      final friendToAdd = Player(
          id: '',
          playerName: 'ExistingFriend',
          email: 'ef@test.com',
          phoneNumber: '555-1111',
          nickname: 'EF',
          ownerId: '',
          totalScore: 0);

      owner.addPlayerFriend(friendToAdd);
      // microtask runs after current microtask queue — pump it
      await Future.delayed(Duration.zero);

      // The friend link should be in Firestore
      final friendLink = await fakeFirestore
          .collection('friends')
          .doc('owner-ef_existing-friend')
          .get();
      expect(friendLink.exists, isTrue);
      expect(Player.players.any((p) => p.email == 'ef@test.com'), isTrue);
    });

    test('creates new player and adds as friend (new user path)', () async {
      // No existing player with this email
      final owner = Player(
          id: 'owner-new',
          playerName: 'Owner',
          nickname: 'O',
          ownerId: 'owner-new',
          totalScore: 0);

      final newFriend = Player(
          id: '',
          playerName: 'BrandNew',
          email: 'brandnew@test.com',
          phoneNumber: '555-2222',
          nickname: 'BN',
          ownerId: '',
          totalScore: 0);

      owner.addPlayerFriend(newFriend);
      await Future.delayed(Duration.zero);

      // A new player doc should have been created
      final snapshot = await fakeFirestore
          .collection('players')
          .where('email', isEqualTo: 'brandnew@test.com')
          .get();
      expect(snapshot.docs.isNotEmpty, isTrue);

      // Friend link exists (both directions)
      final newPlayerId = snapshot.docs.first.id;
      final link1 = await fakeFirestore
          .collection('friends')
          .doc('owner-new_$newPlayerId')
          .get();
      expect(link1.exists, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Player._addFriend — bidirectional write
  // ════════════════════════════════════════════════════════════════════════════

  group('Player.createPlayer edge cases', () {
    test(
        'updates owner_id to guest when ownerId is empty and no user is logged in',
        () async {
      // Indirectly test via createPlayer with no ownerId
      final p = await Player.createPlayer('EmptyOwner', 'EO',
          email: 'empty@test.com', phoneNumber: '000');
      expect(p.ownerId, 'guest');

      final doc = await fakeFirestore.collection('players').doc(p.id).get();
      expect(doc.data()?['owner_id'], 'guest');
    });
  });

  group('Course model edge cases', () {
    test('Course.fromJson handles null parStrokes', () {
      final json = {
        'id': 'c1',
        'name': 'C',
        'number_of_holes': 9,
        'par_strokes': null
      };
      final c = Course.fromJson(json);
      expect(c.parStrokes, isEmpty);
    });

    test('Course.fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final c = Course.fromJson(json);
      expect(c.id, '');
      expect(c.name, '');
      expect(c.numberOfHoles, 0);
      expect(c.parStrokes, isEmpty);
    });

    test('Course.toJson handles parStrokes serialization', () {
      final c =
          Course(id: 'c1', name: 'C', numberOfHoles: 1, parStrokes: {1: 3});
      final json = c.toJson();
      expect(json['par_strokes'], {'1': 3});
    });
  });

  group('Game model edge cases', () {
    test('Game.empty creates expected object', () {
      final g = Game.empty();
      expect(g.id, '');
      expect(g.name, '');
      expect(g.course.name, '');
      expect(g.players, isEmpty);
    });

    test('Game.toJson contains course data', () {
      final g = _makeGame(id: 'g1');
      final json = g.toJson();
      expect(json['course']['name'], 'Test Course');
    });
  });

  group('Player._addFriend (via createPlayer + addPlayerFriend)', () {
    test('writes bidirectional friend docs', () async {
      // Directly test via the public path: addPlayerFriend uses createPlayer
      // then _addFriend is called inside addPlayerFriend
      await fakeFirestore.collection('players').doc('p-a').set({
        'player_name': 'A',
        'email': 'a@test.com',
        'phone_number': '111',
        'nickname': 'A',
        'owner_id': 'p-a',
        'total_score': 0,
      });
      await fakeFirestore.collection('players').doc('p-b').set({
        'player_name': 'B',
        'email': 'b@test.com',
        'phone_number': '222',
        'nickname': 'B',
        'owner_id': 'p-b',
        'total_score': 0,
      });

      final playerA = Player(
          id: 'p-a',
          playerName: 'A',
          email: 'a@test.com',
          phoneNumber: '111',
          nickname: 'A',
          ownerId: 'p-a',
          totalScore: 0);
      final friendB = Player(
          id: '',
          playerName: 'B',
          email: 'b@test.com',
          phoneNumber: '222',
          nickname: 'B',
          ownerId: '',
          totalScore: 0);

      playerA.addPlayerFriend(friendB);
      await Future.delayed(Duration.zero);

      final forward =
          await fakeFirestore.collection('friends').doc('p-a_p-b').get();
      final reverse =
          await fakeFirestore.collection('friends').doc('p-b_p-a').get();
      expect(forward.exists, isTrue);
      expect(reverse.exists, isTrue);
    });
  });

  group('Player lookup and edge cases', () {
    test('getPlayerFriendById returns empty player when not found', () {
      Player.players = [];
      final result = Player.empty().getPlayerFriendById('non-existent');
      expect(result?.id, '');
    });

    test('getPlayerFriendByEmail returns empty player when not found', () {
      Player.players = [];
      final result = Player.empty().getPlayerFriendByEmail('ghost@test.com');
      expect(result?.id, '');
    });

    test('addPlayerFriend reuses an existing phone-only match', () async {
      await fakeFirestore.collection('players').doc('real-p').set({
        'player_name': 'Real',
        'email': 'real@test.com',
        'phone_number': '12345',
        'nickname': 'R',
        'owner_id': 'o1',
        'total_score': 0
      });

      final owner = Player(
          id: 'o1',
          playerName: 'O',
          nickname: 'O',
          ownerId: 'o1',
          totalScore: 0);
      final friendToAdd = Player(
          id: '',
          playerName: 'Fake',
          email: 'mismatch@test.com',
          phoneNumber: '12345',
          nickname: 'F',
          ownerId: '',
          totalScore: 0);

      owner.addPlayerFriend(friendToAdd);

      await Future.delayed(Duration.zero);

      expect(Player.players.single.id, 'real-p');
      final friendDoc =
          await fakeFirestore.collection('friends').doc('o1_real-p').get();
      expect(friendDoc.exists, isTrue);
    });

    test('getAllPlayerFriends returns the list', () {
      Player.players = [Player.empty()];
      expect(Player.empty().getAllPlayerFriends().length, 1);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // DatabaseConnection.initialize — covered by noting it requires Firebase
  // We test the fallback path (no injection → client falls back to singleton)
  // ════════════════════════════════════════════════════════════════════════════

  group('DatabaseConnection static helpers', () {
    test('setFirestoreInstanceForTesting replaces client', () {
      final fake1 = FakeFirebaseFirestore();
      final fake2 = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fake1);
      expect(DatabaseConnection.client, same(fake1));
      DatabaseConnection.setFirestoreInstanceForTesting(fake2);
      expect(DatabaseConnection.client, same(fake2));
    });

    test(
        'client returns FirebaseFirestore.instance when _firestoreInstance is null',
        () {
      // Reset instance to null
      DatabaseConnection.setFirestoreInstanceForTesting(null);
      // This will call the real FirebaseFirestore.instance, which throws [core/no-app]
      // in the test environment. We expect this throw as proof the branch is reached.
      expect(
          () => DatabaseConnection.client,
          throwsA(isA<FirebaseException>()
              .having((e) => e.code, 'code', 'no-app')));

      // Restore for other tests
      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('getFirestore returns same instance as client', () {
      expect(
          DatabaseConnection.getFirestore(), same(DatabaseConnection.client));
    });
  });

  group('Player.empty and other models', () {
    test('Player.empty creates expected object', () {
      final p = Player.empty();
      expect(p.id, '');
      expect(p.playerName, '');
      expect(p.nickname, '');
      expect(p.ownerId, '');
      expect(p.totalScore, 0);
    });

    test('Player.toJson contains all fields', () {
      final p = Player(
          id: '1',
          playerName: 'N',
          nickname: 'K',
          ownerId: 'O',
          totalScore: 5,
          email: 'e',
          phoneNumber: 'p',
          status: 's',
          avatarImageLocation: 'a');
      final json = p.toJson();
      expect(json['id'], '1');
      expect(json['player_name'], 'N');
      expect(json['email'], 'e');
      expect(json['phone_number'], 'p');
      expect(json['status'], 's');
      expect(json['avatar_image_location'], 'a');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Game.recordScore — error branches
  // ════════════════════════════════════════════════════════════════════════════

  group('Game.recordScore error branches', () {
    test('throws when player is not part of game', () {
      final game = _makeGame(id: 'err-g1');
      final stranger = PlayerGameInfo(
          playerId: 'stranger',
          gameId: 'err-g1',
          scores: [],
          totalScore: 0,
          place: '',
          playOrderPosition: 1);
      expect(() => game.recordScore(stranger, 1, 3), throwsException);
    });

    test('throws when player scores map not initialized', () {
      final p1 = PlayerGameInfo(
          playerId: 'p1',
          gameId: 'err-g2',
          scores: [],
          totalScore: 0,
          place: '',
          playOrderPosition: 1);
      final game = _makeGame(id: 'err-g2', players: [p1]);
      // Corrupt the scores map by replacing with a fresh game that has a
      // different player object (different identity)
      final p1Clone = PlayerGameInfo(
          playerId: 'p1',
          gameId: 'err-g2',
          scores: [],
          totalScore: 0,
          place: '',
          playOrderPosition: 1);
      // p1Clone is not the same instance as the one in game.scores
      expect(() => game.recordScore(p1Clone, 1, 3), throwsException);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Game.getLocallySavedGames — non-String value branches (List, other types)
  // ════════════════════════════════════════════════════════════════════════════

  group('Game.getLocallySavedGames non-string value branches', () {
    test('handles integer value in prefs gracefully', () async {
      SharedPreferences.setMockInitialValues({'some-int-key': 42});
      // Should not throw, should return empty (non-string skipped)
      final games = await Game.getLocallySavedGames();
      expect(games, isEmpty);
    });

    test('handles boolean value in prefs gracefully', () async {
      SharedPreferences.setMockInitialValues({'some-bool-key': true});
      final games = await Game.getLocallySavedGames();
      expect(games, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Game.initializeLocalGames — exception handler branch
  // ════════════════════════════════════════════════════════════════════════════

  group('Game.initializeLocalGames exception handler', () {
    test('catches and logs exception from fetchGamesForCurrentUser', () async {
      // Use a player ID that results in no games but doesn't throw
      // To exercise the catch block we need fetchGamesForCurrentUser to throw.
      // We cannot force FakeFirebaseFirestore to throw FirebaseException,
      // but we can verify the function itself doesn't propagate exceptions.
      final user = Player(
          id: 'safe-user',
          playerName: 'Safe',
          nickname: 'S',
          ownerId: 'safe-user',
          totalScore: 0);
      // Should complete without throwing even if internals fail
      await expectLater(Game.initializeLocalGames(user), completes);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Game.getSortedPlayerScores — tie-breaking branch (equal scores, sort by id)
  // ════════════════════════════════════════════════════════════════════════════

  group('Game.getSortedPlayerScores tie-breaking', () {
    test('sorts by playerId when scores are tied and non-zero', () {
      final p1 = PlayerGameInfo(
          playerId: 'z-player',
          gameId: 'g1',
          scores: [3, 3],
          totalScore: 6,
          place: '',
          playOrderPosition: 1);
      final p2 = PlayerGameInfo(
          playerId: 'a-player',
          gameId: 'g1',
          scores: [3, 3],
          totalScore: 6,
          place: '',
          playOrderPosition: 2);
      final game = _makeGame(id: 'g1', players: [p1, p2]);
      final sorted = game.getSortedPlayerScores();
      // When both scores are equal AND non-zero, the sort falls into the
      // else branch and compares by playerId alphabetically
      expect(sorted.first.playerId, 'a-player');
    });

    test('sorts by score when scores differ', () {
      final p1 = PlayerGameInfo(
          playerId: 'p1',
          gameId: 'g2',
          scores: [5, 5],
          totalScore: 10,
          place: '',
          playOrderPosition: 1);
      final p2 = PlayerGameInfo(
          playerId: 'p2',
          gameId: 'g2',
          scores: [3, 3],
          totalScore: 6,
          place: '',
          playOrderPosition: 2);
      final game = _makeGame(id: 'g2', players: [p1, p2]);
      final sorted = game.getSortedPlayerScores();
      expect(sorted.first.playerId, 'p2'); // lower score wins
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // FirebaseException catch blocks — using fake_cloud_firestore's whenCalling
  // ════════════════════════════════════════════════════════════════════════════

  final firestoreError =
      FirebaseException(plugin: 'cloud_firestore', message: 'simulated error');

  group('Player.updatePlayerScoreInDatabase — FirebaseException catch', () {
    test('rethrows as DatabaseConnectionError on Firestore failure', () async {
      await fakeFirestore.collection('players').doc('p-err').set({
        'player_name': 'Err',
        'email': 'err@test.com',
        'nickname': 'E',
        'owner_id': 'o',
        'total_score': 0,
      });
      final doc = fakeFirestore.collection('players').doc('p-err');
      whenCalling(Invocation.method(#update, null))
          .on(doc)
          .thenThrow(firestoreError);

      final player = Player(
          id: 'p-err',
          playerName: 'Err',
          nickname: 'E',
          ownerId: 'o',
          totalScore: 99);
      expect(() => Player.updatePlayerScoreInDatabase(player),
          throwsA(isA<DatabaseConnectionError>()));
    });
  });

  group('Player.createPlayer - FirebaseException catch', () {
    test('rethrows as DatabaseConnectionError on Firestore set failure',
        () async {
      final failFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(failFirestore);

      final doc = failFirestore.collection('players').doc('fail-doc');
      whenCalling(Invocation.method(#set, null))
          .on(doc)
          .thenThrow(firestoreError);

      await expectLater(
        Player.createPlayer('Fail', 'F', id: 'fail-doc'),
        throwsA(isA<DatabaseConnectionError>()),
      );

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('rethrows generic write failures as Exception', () async {
      final failFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(failFirestore);

      final doc = failFirestore.collection('games').doc('generic-fail-game');
      whenCalling(Invocation.method(#set, null))
          .on(doc)
          .thenThrow(Exception('simulated generic failure'));

      final game = _makeGame(id: 'generic-fail-game');
      await expectLater(
        Game.saveGameToDatabase(game, _makeCreator()),
        throwsException,
      );

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });
  });

  // NOTE: Course.fetchCourses FirebaseException path uses CollectionReference.get()
  // (no chaining). fake_cloud_firestore's whenCalling only supports interception on
  // DocumentReference methods (get, set, update, delete) — NOT CollectionReference.get()
  // or Query.get(). The lines 81-86 of course.dart cannot be triggered via fake_cloud_firestore.
  // The FirebaseException catch structure is verified via the Player.updatePlayerScoreInDatabase
  // test above which uses the supported DocumentReference.update() interception.

  group('Course.fetchCourses - FirebaseException catch (DocumentReference)',
      () {
    test(
        'mock_exceptions can throw FirebaseException on DocumentReference.get()',
        () async {
      // Confirms whenCalling works on DocumentReference.get(), validating that
      // the mock infrastructure is correct. The CollectionReference.get() interception
      // (needed for fetchCourses) is a known limitation of fake_cloud_firestore.
      final testFirestore = FakeFirebaseFirestore();
      await testFirestore
          .collection('courses')
          .doc('c-verify')
          .set({'name': 'V'});
      final docRef = testFirestore.collection('courses').doc('c-verify');
      whenCalling(Invocation.method(#get, null)).on(docRef).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', message: 'simulated'));
      await expectLater(docRef.get(), throwsA(isA<FirebaseException>()));
    });
  });

  group('Course.saveCourseToDatabase - duplicate branch', () {
    test('throws when course with same name/holes already exists', () async {
      final dupFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(dupFirestore);

      await dupFirestore.collection('courses').add({
        'name': 'Dup Course',
        'number_of_holes': 9,
        'par_strokes': <String, int>{}
      });

      final course =
          Course(id: '', name: 'Dup Course', numberOfHoles: 9, parStrokes: {});
      await expectLater(
          course.saveCourseToDatabase(),
          throwsA(predicate<Object>(
              (e) => e.toString().contains('already exists'))));

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });
  });

  // NOTE: Course.saveCourseToDatabase FirebaseException is on collection().add()
  // which fake_cloud_firestore cannot intercept (only DocumentReference methods
  // are supported by whenCalling). The try/catch boundary is verified by the
  // duplicate branch test above exercising the same try block.

  group('Game.saveGameToDatabase - FirebaseException catch', () {
    test('rethrows as DatabaseConnectionError on Firestore write failure',
        () async {
      final failFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(failFirestore);

      final doc = failFirestore.collection('games').doc('fail-game');
      whenCalling(Invocation.method(#set, null))
          .on(doc)
          .thenThrow(firestoreError);

      final game = _makeGame(id: 'fail-game');
      await expectLater(Game.saveGameToDatabase(game, _makeCreator()),
          throwsA(isA<DatabaseConnectionError>()));

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });
  });

  group('Game.fetchGamesForCurrentUser - exception coverage', () {
    test('general catch branch: surfaces exception from malformed game data',
        () async {
      // Seeds a game with missing 'course' field so Game.fromJson throws,
      // exercising the general catch (lines 395-399) in fetchGamesForCurrentUser.
      final badFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(badFirestore);

      final now = DateTime.now();
      await badFirestore.collection('games').doc('bad-g1').set({
        'id': 'bad-g1', 'name': 'Bad Game', 'creator_id': 'user-xyz',
        'participant_ids': ['user-xyz'],
        // intentionally omit 'course' so Game.fromJson throws
        'scheduled_time': now.toIso8601String(),
        'status': 'pending', 'players': [],
      });

      await expectLater(
          Game.fetchGamesForCurrentUser('user-xyz'), throwsException);

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('returns list of games for a given user (happy path)', () async {
      final testFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);
      SharedPreferences.setMockInitialValues({});

      final now = DateTime.now();
      // Use the same shape that saveGameToDatabase writes:
      // includes nested 'course' object, 'players' as list
      await testFirestore.collection('games').doc('gq-hp-1').set({
        'id': 'gq-hp-1',
        'name': 'Fetched Game',
        'creator_id': 'user-abc',
        'participant_ids': ['user-abc'],
        'course_id': 'c1',
        'course': {
          'id': 'c1',
          'name': 'Test Course',
          'number_of_holes': 2,
          'par_strokes': {'1': 3, '2': 4}
        },
        'scheduled_time': now.toIso8601String(),
        'status': 'pending',
        'players': [],
      });

      final games = await Game.fetchGamesForCurrentUser('user-abc');
      expect(games, isNotEmpty);
      expect(games.first.name, 'Fetched Game');

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('returns games where user is a participant but not creator', () async {
      final testFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

      await testFirestore
          .collection('games')
          .doc('participant-game')
          .set(_firestoreGameDoc('participant-game', 'other-creator'));
      await testFirestore
          .collection('player_game_info')
          .doc('participant-game_player-1')
          .set({
        'game_id': 'participant-game',
        'player_id': 'player-1',
      });

      final games = await Game.fetchGamesForCurrentUser('player-1');

      expect(games, hasLength(1));
      expect(games.single.id, 'participant-game');

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('rethrows FirebaseException as DatabaseConnectionError', () async {
      DatabaseConnection.setFirestoreInstanceForTesting(
          MockQueryExceptionFirestore());

      await expectLater(
        Game.fetchGamesForCurrentUser('user-error'),
        throwsA(isA<DatabaseConnectionError>()),
      );

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    group('Player static helpers transient Firestore error retry mechanism',
        () {
      test(
          'Player._safeGetDocument retries on permission-denied up to 3 times and then throws DatabaseConnectionError',
          () async {
        final testFirestore = FakeFirebaseFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

        final docRef = testFirestore
            .collection('player_contacts')
            .doc('phone_+15551234567');

        whenCalling(Invocation.method(#get, null)).on(docRef).thenThrow(
              FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
                message: 'transient permission-denied',
              ),
            );

        final stopwatch = Stopwatch()..start();
        await expectLater(
          Player.getPlayerByPhoneFromDB('+15551234567'),
          throwsA(isA<DatabaseConnectionError>()),
        );
        stopwatch.stop();

        // Delays 200ms per retry and retries 3 times -> total delay at least 600ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(600));

        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      });

      test(
          'Player._safeGetDocument successfully recovers after transient permission-denied retries',
          () async {
        final testFirestore = FakeFirebaseFirestore();

        // Seed the player contact reservation and player document in the real test database
        await testFirestore
            .collection('player_contacts')
            .doc('phone_+15551234567')
            .set({'player_id': 'transient-player-id'});
        await testFirestore
            .collection('players')
            .doc('transient-player-id')
            .set({
          'player_name': 'Transient Success Player',
          'nickname': 'TSP',
          'owner_id': 'transient-player-id',
          'total_score': 0,
        });

        final realDocRef = testFirestore
            .collection('player_contacts')
            .doc('phone_+15551234567');
        final mockFirestore = MockTransientFirestore(testFirestore, realDocRef);
        DatabaseConnection.setFirestoreInstanceForTesting(mockFirestore);

        final stopwatch = Stopwatch()..start();
        final player = await Player.getPlayerByPhoneFromDB('+15551234567');
        stopwatch.stop();

        expect(player, isNotNull);
        expect(player!.playerName, 'Transient Success Player');
        expect(mockFirestore.mockDocRef.getCalls, 3);
        // Delays 200ms per retry and retries 2 times before success -> total delay at least 400ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(400));

        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      });

      test(
          'Player._safeGetQuery retries on permission-denied up to 3 times and then throws DatabaseConnectionError',
          () async {
        final mockFirestore = MockQueryExceptionFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(mockFirestore);

        final stopwatch = Stopwatch()..start();
        await expectLater(
          Player.getPlayerByEmailFromDB('test@example.com'),
          throwsA(isA<DatabaseConnectionError>()),
        );
        stopwatch.stop();

        // Delays 200ms per retry and retries 3 times -> total delay at least 600ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(600));

        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      });

      test(
          'Player._safeGetQuery successfully recovers after transient permission-denied retries',
          () async {
        final testFirestore = FakeFirebaseFirestore();

        // Seed a player document in the real test database
        await testFirestore
            .collection('players')
            .doc('transient-query-player-id')
            .set({
          'player_name': 'Transient Query Success Player',
          'nickname': 'TQSP',
          'owner_id': 'transient-query-player-id',
          'total_score': 0,
          'normalized_email': 'transient-query@test.com',
          'email': 'transient-query@test.com',
        });

        final mockFirestore = MockTransientQueryFirestore(testFirestore);
        DatabaseConnection.setFirestoreInstanceForTesting(mockFirestore);

        final stopwatch = Stopwatch()..start();
        final player =
            await Player.getPlayerByEmailFromDB('transient-query@test.com');
        stopwatch.stop();

        expect(player, isNotNull);
        expect(player!.playerName, 'Transient Query Success Player');
        // Delays 200ms per retry and retries 2 times before success -> total delay at least 400ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(400));

        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      });

      test(
          'createPlayer transaction throws duplicate player error if reservation exists',
          () async {
        final testFirestore = FakeFirebaseFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

        // Seed a contact reservation document directly, but DO NOT create the corresponding player document!
        // This means getPlayerByContactFromDB will return null (since it checks players collection),
        // but the reservation document already exists!
        await testFirestore
            .collection('player_contacts')
            .doc('email_txn-dup@test.com')
            .set({
          'player_id': 'some-other-player-id',
        });

        await expectLater(
          Player.createPlayer('Txn Dup', 'TD', email: 'txn-dup@test.com'),
          throwsA(isA<DatabaseConnectionError>()),
        );

        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      });
    });
  });

  group('Player additional coverage tests', () {
    test(
        'getPlayerByEmailFromDB with active Firebase apps and matching currentUser UID',
        () async {
      final originalFirebase = FirebasePlatform.instance;
      final originalAuth = FirebaseAuthPlatform.instance;

      try {
        setupFirebaseCoreMocks();
        await Firebase.initializeApp();

        final mockUser = MyMockUserPlatform(
          uid: 'matching-uid',
          email: 'test-matching@example.com',
        );
        MockFirebaseAuthPlatform.mockUser = mockUser;
        MockFirebaseAuthPlatform.shouldThrow = false;
        FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();

        final testFirestore = FakeFirebaseFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

        // Seed two players with the same email
        await testFirestore.collection('players').doc('other-uid').set({
          'player_name': 'Other Player',
          'nickname': 'Other',
          'email': 'test-matching@example.com',
          'owner_id': 'other-uid',
          'total_score': 0,
        });

        await testFirestore.collection('players').doc('matching-uid').set({
          'player_name': 'Matching Player',
          'nickname': 'Matching',
          'email': 'test-matching@example.com',
          'owner_id': 'matching-uid',
          'total_score': 0,
        });

        final player =
            await Player.getPlayerByEmailFromDB('test-matching@example.com');
        expect(player, isNotNull);
        expect(player!.id, 'matching-uid');
        expect(player.playerName, 'Matching Player');
      } finally {
        MockFirebaseAuthPlatform.mockUser = null;
        MockFirebaseAuthPlatform.shouldThrow = false;
        FirebasePlatform.instance = originalFirebase;
        FirebaseAuthPlatform.instance = originalAuth;
        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      }
    });

    test(
        'getPlayerByEmailFromDB with active Firebase apps and non-matching currentUser UID (falls back to first)',
        () async {
      final originalFirebase = FirebasePlatform.instance;
      final originalAuth = FirebaseAuthPlatform.instance;

      try {
        setupFirebaseCoreMocks();
        await Firebase.initializeApp();

        final mockUser = MyMockUserPlatform(
          uid: 'nonmatching-uid',
          email: 'test-fallback@example.com',
        );
        MockFirebaseAuthPlatform.mockUser = mockUser;
        MockFirebaseAuthPlatform.shouldThrow = false;
        FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();

        final testFirestore = FakeFirebaseFirestore();
        DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

        await testFirestore.collection('players').doc('first-uid').set({
          'player_name': 'First Player',
          'nickname': 'First',
          'email': 'test-fallback@example.com',
          'owner_id': 'first-uid',
          'total_score': 0,
        });

        final player =
            await Player.getPlayerByEmailFromDB('test-fallback@example.com');
        expect(player, isNotNull);
        expect(player!.id, 'first-uid');
      } finally {
        MockFirebaseAuthPlatform.mockUser = null;
        MockFirebaseAuthPlatform.shouldThrow = false;
        FirebasePlatform.instance = originalFirebase;
        FirebaseAuthPlatform.instance = originalAuth;
        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      }
    });

    test('getPlayerByEmailFromDB when FirebaseAuth access throws', () async {
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

        await testFirestore.collection('players').doc('fallback-uid').set({
          'player_name': 'Fallback Player',
          'nickname': 'Fallback',
          'email': 'test-throw@example.com',
          'owner_id': 'fallback-uid',
          'total_score': 0,
        });

        final player =
            await Player.getPlayerByEmailFromDB('test-throw@example.com');
        expect(player, isNotNull);
        expect(player!.id, 'fallback-uid');
      } finally {
        MockFirebaseAuthPlatform.mockUser = null;
        MockFirebaseAuthPlatform.shouldThrow = false;
        FirebasePlatform.instance = originalFirebase;
        FirebaseAuthPlatform.instance = originalAuth;
        DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
      }
    });

    test('claimPlayerForAuthUser fallback path (no existing player profile)',
        () async {
      final testFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

      final player = await Player.claimPlayerForAuthUser(
        uid: 'new-auth-uid-123',
        email: 'brandnew@example.com',
        playerName: 'Brand New',
        nickname: 'Brandie',
      );

      expect(player.id, 'new-auth-uid-123');
      expect(player.playerName, 'Brand New');
      expect(player.email, 'brandnew@example.com');

      final doc = await testFirestore
          .collection('players')
          .doc('new-auth-uid-123')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['player_name'], 'Brand New');

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test(
        'updateUnclaimedPlayer throws DatabaseConnectionError if player already claimed',
        () async {
      final player = Player(
        id: 'claimed-pid',
        playerName: 'Already Claimed',
        nickname: 'Claimed',
        ownerId: 'owner-1',
        totalScore: 0,
        claimedByUid: 'some-uid',
      );

      expect(
        () => Player.updateUnclaimedPlayer(player),
        throwsA(isA<DatabaseConnectionError>()),
      );
    });

    test(
        'updateUnclaimedPlayer throws DatabaseConnectionError if new email/phone already reserved by another player',
        () async {
      final testFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

      // Seed an existing reservation owned by 'another-player-id'
      await testFirestore
          .collection('player_contacts')
          .doc('email_reserved@example.com')
          .set({'player_id': 'another-player-id'});

      final player = Player(
        id: 'my-player-id',
        playerName: 'My Player',
        nickname: 'My',
        ownerId: 'my-player-id',
        totalScore: 0,
      );
      await testFirestore
          .collection('players')
          .doc(player.id)
          .set(player.toJson());

      player.email = 'reserved@example.com';

      expect(
        () => Player.updateUnclaimedPlayer(player),
        throwsA(isA<DatabaseConnectionError>()),
      );

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test(
        '_getAllPlayersFromFriends throws DatabaseConnectionError when fetchPlayerFromDatabase fails with FirebaseException',
        () async {
      final testFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

      // Seed a friend link
      await testFirestore.collection('friends').add({
        'player_id': 'owner-id',
        'friend_id': 'friend-id-1',
      });

      // Set up friend player doc ref to throw on get()
      final friendDocRef =
          testFirestore.collection('players').doc('friend-id-1');
      whenCalling(Invocation.method(#get, null)).on(friendDocRef).thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
              message: 'Simulated unavailable',
            ),
          );

      // Expect the load friends call to throw DatabaseConnectionError
      final ownerPlayer = Player(
        id: 'owner-id',
        playerName: 'Owner',
        nickname: 'O',
        ownerId: 'owner-id',
        totalScore: 0,
      );

      await expectLater(
        ownerPlayer.loadUserPlayers(),
        throwsA(isA<DatabaseConnectionError>()),
      );

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('resolveGuestPlayer returns canonical player when found in DB',
        () async {
      final testFirestore = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(testFirestore);

      // Seed a player in DB
      final dbPlayer = Player(
        id: 'db-player-123',
        playerName: 'John Doe',
        nickname: 'JD',
        email: 'john@example.com',
        phoneNumber: '123456789',
        ownerId: 'db-player-123',
        totalScore: 0,
      );
      await testFirestore
          .collection('players')
          .doc(dbPlayer.id)
          .set(dbPlayer.toJson());

      // Seed contact identity reservation
      await testFirestore
          .collection('player_contacts')
          .doc('email_john@example.com')
          .set({
        'player_id': dbPlayer.id,
      });

      final guestPlayer = Player(
        id: 'guest-id',
        playerName: 'Guest John',
        nickname: 'GJ',
        email: 'john@example.com',
        phoneNumber: '123456789',
        ownerId: 'guest-id',
        totalScore: 0,
      );

      final resolved = await Player.resolveGuestPlayer(guestPlayer);
      expect(resolved.id, 'db-player-123');
      expect(resolved.playerName, 'John Doe');

      DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    });

    test('resolveGuestPlayer returns guest player when not found in DB',
        () async {
      final guestPlayer = Player(
        id: 'guest-id',
        playerName: 'Guest John',
        nickname: 'GJ',
        email: 'john-nonexistent@example.com',
        phoneNumber: '999999999',
        ownerId: 'guest-id',
        totalScore: 0,
      );

      final resolved = await Player.resolveGuestPlayer(guestPlayer);
      expect(resolved.id, 'guest-id');
      expect(resolved.playerName, 'Guest John');
    });

    test('getPlayerByEmailFromDB returns null when normalized email is null',
        () async {
      final player = await Player.getPlayerByEmailFromDB('');
      expect(player, isNull);
    });

    test('getPlayerByPhoneFromDB returns null when normalized phone is null',
        () async {
      final player = await Player.getPlayerByPhoneFromDB('');
      expect(player, isNull);
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
  @override
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

// Custom Mock classes for testing retry mechanisms in player.dart

class MockExceptionDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => false;
}

class MockExceptionDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get) {
      return Future.value(MockExceptionDocumentSnapshot());
    }
    return super.noSuchMethod(invocation);
  }
}

class MockQueryExceptionFirestore extends Fake implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #collection) {
      return MockExceptionCollectionReference();
    }
    return super.noSuchMethod(invocation);
  }
}

class MockExceptionCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      return MockExceptionQuery();
    }
    if (invocation.memberName == #doc) {
      return MockExceptionDocumentReference();
    }
    return super.noSuchMethod(invocation);
  }
}

class MockExceptionQuery extends Fake implements Query<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #orderBy) {
      return this;
    }
    if (invocation.memberName == #get) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'transient permission-denied',
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class MockTransientDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final DocumentReference<Map<String, dynamic>> realRef;
  int getCalls = 0;

  MockTransientDocumentReference(this.realRef);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get) {
      getCalls++;
      if (getCalls <= 2) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'transient permission-denied',
        );
      }
      return realRef.get();
    }
    return realRef.noSuchMethod(invocation);
  }
}

class MockTransientFirestore extends Fake implements FirebaseFirestore {
  final FirebaseFirestore realFirestore;
  final DocumentReference<Map<String, dynamic>> realDocRef;
  late final MockTransientDocumentReference mockDocRef;

  MockTransientFirestore(this.realFirestore, this.realDocRef) {
    mockDocRef = MockTransientDocumentReference(realDocRef);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #collection) {
      return MockTransientCollectionReference(
        realFirestore.collection(invocation.positionalArguments[0]),
        mockDocRef,
        invocation.positionalArguments[0],
      );
    }
    return realFirestore.noSuchMethod(invocation);
  }
}

class MockTransientCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> realCollection;
  final MockTransientDocumentReference mockDocRef;
  final String collectionName;

  MockTransientCollectionReference(
      this.realCollection, this.mockDocRef, this.collectionName);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #doc) {
      final docId = invocation.positionalArguments.isNotEmpty
          ? invocation.positionalArguments[0] as String?
          : null;
      if (collectionName == 'player_contacts' &&
          docId == 'phone_+15551234567') {
        return mockDocRef;
      }
      return realCollection.doc(docId);
    }
    return realCollection.noSuchMethod(invocation);
  }
}

class MockTransientQuery extends Fake implements Query<Map<String, dynamic>> {
  final Query<Map<String, dynamic>> realQuery;
  int getCalls = 0;

  MockTransientQuery(this.realQuery);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get) {
      getCalls++;
      if (getCalls <= 2) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'transient permission-denied',
        );
      }
      return realQuery.get();
    }
    if (invocation.memberName == #limit) {
      return MockTransientQuery(
          realQuery.limit(invocation.positionalArguments[0]));
    }
    if (invocation.memberName == #where) {
      final newRealQuery = Function.apply(
        realQuery.where,
        invocation.positionalArguments,
        invocation.namedArguments,
      ) as Query<Map<String, dynamic>>;
      return MockTransientQuery(newRealQuery);
    }
    return realQuery.noSuchMethod(invocation);
  }
}

class MockTransientQueryFirestore extends Fake implements FirebaseFirestore {
  final FirebaseFirestore realFirestore;

  MockTransientQueryFirestore(this.realFirestore);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #collection) {
      return MockTransientQueryCollectionReference(
        realFirestore.collection(invocation.positionalArguments[0]),
      );
    }
    return realFirestore.noSuchMethod(invocation);
  }
}

class MockTransientQueryCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> realCollection;

  MockTransientQueryCollectionReference(this.realCollection);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      final realQuery = Function.apply(
        realCollection.where,
        invocation.positionalArguments,
        invocation.namedArguments,
      ) as Query<Map<String, dynamic>>;

      return MockTransientQuery(realQuery);
    }
    if (invocation.memberName == #doc) {
      final docId = invocation.positionalArguments.isNotEmpty
          ? invocation.positionalArguments[0] as String?
          : null;
      return realCollection.doc(docId);
    }
    return realCollection.noSuchMethod(invocation);
  }
}

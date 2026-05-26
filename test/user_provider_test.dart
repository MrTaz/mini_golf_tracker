import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mock_exceptions/src/mock_exceptions.dart' as me;
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late UserProvider userProvider;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    me.expectations.clear();

    SharedPreferences.setMockInitialValues({});

    userProvider = UserProvider();
    userProvider.resetForTesting();
    userProvider.setAuthInstanceForTesting(mockAuth);
  });

  group('UserProvider Tests', () {
    test('Initial state is not logged in', () {
      expect(userProvider.loggedInUser, isNull);
    });

    test('login() updates state and persists user', () async {
      final player = Player(
        id: 'user123',
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: 'user123',
        totalScore: 100,
        email: 'test@example.com',
      );

      await userProvider.login(player);

      expect(userProvider.loggedInUser, isNotNull);
      expect(userProvider.loggedInUser!.email, 'test@example.com');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('email'), 'test@example.com');
      expect(prefs.getString('loggedInUser'), isNotNull);
    });

    test('login() adopts local guest games into Firestore', () async {
      final player = Player(
        id: 'user123',
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: 'user123',
        totalScore: 100,
        email: 'test@example.com',
      );
      await Game.saveLocalGame(_makeUserProviderGame('guest-local'));

      await userProvider.login(player);

      final gameDoc =
          await fakeFirestore.collection('games').doc('guest-local').get();
      expect(gameDoc.exists, isTrue);
      expect(gameDoc.data()?['creator_id'], player.id);
    });

    test('loggedInUser setter updates state', () {
      final player = Player(
        id: 'user123',
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: 'user123',
        totalScore: 100,
      );
      userProvider.loggedInUser = player;
      expect(userProvider.loggedInUser, player);
    });

    test('logout() clears state and signed out from Firebase', () async {
      final player = Player(
        id: 'user123',
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: 'user123',
        totalScore: 100,
        email: 'test@example.com',
      );

      await userProvider.login(player);
      expect(userProvider.loggedInUser, isNotNull);

      await userProvider.logout();

      expect(userProvider.loggedInUser, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('email'), isNull);
      expect(prefs.getString('loggedInUser'), isNull);
    });

    test('logout() clears local games and guest players', () async {
      final player = Player(
        id: 'user123',
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: 'user123',
        totalScore: 100,
        email: 'test@example.com',
      );
      await userProvider.login(player);
      await Game.saveLocalGame(_makeUserProviderGame('local-after-login'));
      Player.players = [
        Player(
          id: 'guest-player',
          playerName: 'Guest Player',
          nickname: 'Guest',
          ownerId: 'guest',
          totalScore: 0,
        ),
      ];
      await Player.saveLocalGuestPlayers();

      await userProvider.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('local-after-login'), isNull);
      expect(prefs.getString('guest_players'), isNull);
      expect(Player.players, isEmpty);
    });

    test('initialize() restores state from SharedPreferences', () async {
      final player = Player(
        id: 'user123',
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: 'user123',
        totalScore: 100,
        email: 'test@example.com',
      );

      SharedPreferences.setMockInitialValues({
        'email': 'test@example.com',
        'loggedInUser': jsonEncode(player.toJson()),
      });

      await userProvider.initialize();

      expect(userProvider.loggedInUser, isNotNull);
      expect(userProvider.loggedInUser!.email, 'test@example.com');
    });

    test('Listen to auth state changes - user logged in via Firebase',
        () async {
      // Setup: user in Firestore but not in local state
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      final uid = userCredential.user!.uid;

      final player = Player(
        id: uid,
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: uid,
        totalScore: 100,
        email: 'test@example.com',
      );

      await fakeFirestore.collection('players').doc(uid).set(player.toJson());

      await userProvider.initialize();
      // Initially not logged in until the stream processes
      // Wait for stream listener to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: local state should be updated automatically
      expect(userProvider.loggedInUser, isNotNull);
      expect(userProvider.loggedInUser!.email, 'test@example.com');
    });

    test('Listen to auth state changes - user logged out via Firebase',
        () async {
      // Setup: user logged in locally and in Firebase
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      final uid = userCredential.user!.uid;

      final player = Player(
        id: uid,
        playerName: 'Test User',
        nickname: 'Tester',
        ownerId: uid,
        totalScore: 100,
        email: 'test@example.com',
      );

      await userProvider.login(player);

      await userProvider.initialize();
      expect(userProvider.loggedInUser, isNotNull);

      // Act: Trigger Firebase Auth logout
      await mockAuth.signOut();

      // Wait for stream listener to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: local state should be cleared automatically
      expect(userProvider.loggedInUser, isNull);
    });

    test('Auto-creation of Firestore profile for new social login', () async {
      // Setup: No player in Firestore
      await userProvider.initialize();
      expect(userProvider.loggedInUser, isNull);

      // Act: Trigger login for a user that doesn't exist in Firestore
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'new_google_user@example.com',
        password: 'password123',
      );

      // Simulate Firebase user having a display name and photo
      // Note: MockUser doesn't have a direct setter for these, but we can mock them if needed
      // For simplicity, we just check that a profile is created.

      // Wait for stream listener to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Profile should be auto-created in Firestore
      final uid = userCredential.user!.uid;
      final doc = await fakeFirestore.collection('players').doc(uid).get();

      expect(doc.exists, isTrue,
          reason: 'Firestore profile should be created with UID as ID');
      expect(doc.data()?['email'], 'new_google_user@example.com');

      // Assert: Local state should be updated
      expect(userProvider.loggedInUser, isNotNull);
      expect(userProvider.loggedInUser!.id, uid);
    });

    test('social login claims matching player when auth email is verified',
        () async {
      await fakeFirestore.collection('players').doc('existing-player').set({
        'player_name': 'Existing Player',
        'nickname': 'Existing',
        'owner_id': 'creator-1',
        'email': 'claim@example.com',
        'total_score': 0,
      });

      await userProvider.initialize();
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'claim@example.com',
        password: 'password123',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final claimedDoc = await fakeFirestore
          .collection('players')
          .doc('existing-player')
          .get();
      expect(userProvider.loggedInUser!.id, 'existing-player');
      expect(
        claimedDoc.data()?['claimed_by_uid'],
        userCredential.user!.uid,
      );
    });

    test('auth state bypass claims matching test account before verification',
        () async {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'auth-user',
          email: 'test@example.com',
          isEmailVerified: false,
        ),
      );
      userProvider.setAuthInstanceForTesting(mockAuth);
      await fakeFirestore.collection('players').doc('existing-player').set({
        'player_name': 'Existing Player',
        'nickname': 'Existing',
        'owner_id': 'creator-1',
        'email': 'test@example.com',
        'normalized_email': 'test@example.com',
        'total_score': 0,
      });

      await userProvider.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      final claimedDoc = await fakeFirestore
          .collection('players')
          .doc('existing-player')
          .get();
      expect(userProvider.loggedInUser?.id, 'existing-player');
      expect(userProvider.pendingClaimPlayer, isNull);
      expect(claimedDoc.data()?['claimed_by_uid'], 'auth-user');
    });

    test('matching unverified auth user enters pending claim state', () async {
      mockAuth = MockFirebaseAuth(verifyEmailAutomatically: false);
      userProvider.setAuthInstanceForTesting(mockAuth);
      await fakeFirestore.collection('players').doc('existing-player').set({
        'player_name': 'Existing Player',
        'nickname': 'Existing',
        'owner_id': 'creator-1',
        'email': 'claim@example.com',
        'normalized_email': 'claim@example.com',
        'total_score': 0,
      });

      await userProvider.initialize();
      await mockAuth.createUserWithEmailAndPassword(
        email: 'claim@example.com',
        password: 'password123',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(userProvider.loggedInUser, isNull);
      expect(userProvider.pendingClaimPlayer?.id, 'existing-player');
    });

    test('refreshPendingClaim claims after verification changes', () async {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'auth-user',
          email: 'claim@example.com',
          isEmailVerified: false,
        ),
      );
      userProvider.setAuthInstanceForTesting(mockAuth);
      await fakeFirestore.collection('players').doc('existing-player').set({
        'player_name': 'Existing Player',
        'nickname': 'Existing',
        'owner_id': 'creator-1',
        'email': 'claim@example.com',
        'normalized_email': 'claim@example.com',
        'total_score': 0,
      });

      await userProvider.initialize();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(userProvider.pendingClaimPlayer?.id, 'existing-player');

      mockAuth.mockUser = MockUser(
        uid: 'auth-user',
        email: 'claim@example.com',
        isEmailVerified: true,
      );
      final claimedPlayer = await userProvider.refreshPendingClaim();

      expect(claimedPlayer?.id, 'existing-player');
      expect(userProvider.loggedInUser?.id, 'existing-player');
      expect(userProvider.pendingClaimPlayer, isNull);
    });

    test('refreshPendingClaim bypass claims matching test account', () async {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'auth-user',
          email: 'test@example.com',
          isEmailVerified: false,
        ),
      );
      userProvider.setAuthInstanceForTesting(mockAuth);
      await fakeFirestore.collection('players').doc('existing-player').set({
        'player_name': 'Existing Player',
        'nickname': 'Existing',
        'owner_id': 'creator-1',
        'email': 'test@example.com',
        'normalized_email': 'test@example.com',
        'total_score': 0,
      });

      final claimedPlayer = await userProvider.refreshPendingClaim();

      expect(claimedPlayer?.id, 'existing-player');
      expect(userProvider.loggedInUser?.id, 'existing-player');
      expect(userProvider.pendingClaimPlayer, isNull);
    });

    test('refreshPendingClaim preserves pending state before verification',
        () async {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'auth-user',
          email: 'claim@example.com',
          isEmailVerified: false,
        ),
      );
      userProvider.setAuthInstanceForTesting(mockAuth);
      await fakeFirestore.collection('players').doc('existing-player').set({
        'player_name': 'Existing Player',
        'nickname': 'Existing',
        'owner_id': 'creator-1',
        'email': 'claim@example.com',
        'normalized_email': 'claim@example.com',
        'total_score': 0,
      });

      await userProvider.initialize();
      await Future.delayed(const Duration(milliseconds: 100));
      final claimedPlayer = await userProvider.refreshPendingClaim();

      expect(claimedPlayer, isNull);
      expect(userProvider.pendingClaimPlayer?.id, 'existing-player');
    });

    test('refreshPendingClaim returns null if no user is signed in', () async {
      mockAuth = MockFirebaseAuth();
      userProvider.setAuthInstanceForTesting(mockAuth);
      final result = await userProvider.refreshPendingClaim();
      expect(result, isNull);
    });

    test(
        'Listen to auth state changes - error inside listener is caught and logged',
        () async {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'error-user', email: 'error@example.com'),
      );
      userProvider.setAuthInstanceForTesting(mockAuth);

      final docRef = fakeFirestore.collection('players').doc('error-user');
      whenCalling(Invocation.method(#get, null)).on(docRef).thenThrow(
          FirebaseException(
              plugin: 'cloud_firestore', message: 'Simulated error'));

      await userProvider.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(userProvider.loggedInUser, isNull);
    });
  });
}

Game _makeUserProviderGame(String id) {
  return Game(
    id: id,
    name: 'Local Game',
    course: Course(
      id: 'course-1',
      name: 'Test Course',
      numberOfHoles: 1,
      parStrokes: {1: 3},
    ),
    players: [],
    scheduledTime: DateTime(2026, 5, 17),
  );
}

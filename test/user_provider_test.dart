import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/database_connection.dart';
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

    test('Listen to auth state changes - user logged in via Firebase', () async {
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

    test('Listen to auth state changes - user logged out via Firebase', () async {
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
      
      expect(doc.exists, isTrue, reason: 'Firestore profile should be created with UID as ID');
      expect(doc.data()?['email'], 'new_google_user@example.com');
      
      // Assert: Local state should be updated
      expect(userProvider.loggedInUser, isNotNull);
      expect(userProvider.loggedInUser!.id, uid);
    });
  });
}

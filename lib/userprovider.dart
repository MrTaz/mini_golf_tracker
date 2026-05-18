import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() => _instance;

  UserProvider._internal();

  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authStateSubscription;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  // For testing purposes
  void setAuthInstanceForTesting(FirebaseAuth instance) {
    _auth = instance;
  }

  Player? _loggedInUser;
  Player? get loggedInUser => _loggedInUser;
  Player? _pendingClaimPlayer;
  Player? get pendingClaimPlayer => _pendingClaimPlayer;
  List<Player> players = [];

  // For testing purposes
  @visibleForTesting
  void resetForTesting() {
    _loggedInUser = null;
    _pendingClaimPlayer = null;
    players = [];
    _auth = null;
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }

  set loggedInUser(Player? player) {
    _loggedInUser = player;
    notifyListeners();
  }

  void beginPendingClaim(Player player) {
    _pendingClaimPlayer = player;
    notifyListeners();
  }

  Future<void> login(Player player) async {
    _loggedInUser = player;
    _pendingClaimPlayer = null;
    final prefs = await SharedPreferences.getInstance();
    if (player.email != null && player.email!.isNotEmpty) {
      await prefs.setString("email", player.email!);
    }
    await prefs.setString("loggedInUser", jsonEncode(player));
    await Game.initializeLocalGames(player);
    notifyListeners();
  }

  Future<void> logout() async {
    await auth.signOut();
    _loggedInUser = null;
    _pendingClaimPlayer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("email");
    await prefs.remove("loggedInUser");
    await Game.clearLocallySavedGames();
    await Player.clearLocalGuestPlayers();
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    final loggedInUserJson = prefs.getString("loggedInUser");

    if (email != null && loggedInUserJson != null) {
      _loggedInUser = Player.fromJson(jsonDecode(loggedInUserJson));
      notifyListeners();
    }

    // Listen to Firebase Auth changes
    await _authStateSubscription?.cancel();
    _authStateSubscription = auth.authStateChanges().listen((User? user) async {
      final String? listenerTargetUid = user?.uid;

      if (user == null) {
        if (_loggedInUser != null || _pendingClaimPlayer != null) {
          _loggedInUser = null;
          _pendingClaimPlayer = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove("email");
          await prefs.remove("loggedInUser");
          await Game.clearLocallySavedGames();
          await Player.clearLocalGuestPlayers();
          notifyListeners();
        }
      } else {
        // If Firebase says we are logged in, but our local state is empty or different,
        // try to fetch the player profile using the UID.
        if (_loggedInUser == null || _loggedInUser!.id != user.uid) {
          Player? player = await Player.fetchPlayerForAuthUid(user.uid);

          // Verify we are still looking at the same user before updating state
          if (auth.currentUser?.uid != listenerTargetUid) return;

          if (player != null) {
            // Update avatar if provided by Firebase and not set in player profile
            if (user.photoURL != null &&
                player.avatarImageLocation != user.photoURL) {
              player.avatarImageLocation = user.photoURL;
            }
            await login(player);
          } else {
            final claimedPlayer = await Player.claimPlayerForVerifiedAuthUser(
              uid: user.uid,
              email: user.email,
              emailVerified: user.emailVerified,
              phoneNumber: user.phoneNumber,
            );
            if (claimedPlayer != null) {
              await login(claimedPlayer);
              return;
            }

            final existingCandidate = await Player.getPlayerByContactFromDB(
              user.email,
              user.phoneNumber,
            );
            if (existingCandidate != null) {
              _pendingClaimPlayer = existingCandidate;
              notifyListeners();
              return;
            }

            // New user from social login (like Google) - create their profile
            Utilities.debugPrintWithCallerInfo(
                'Creating new player profile for social user: ${user.email}');
            Utilities.debugPrintWithCallerInfo(
                'No Firestore profile found for user ${user.email}. Creating one now...');

            final newUserProfile = await Player.createPlayer(
              user.displayName ?? 'New User',
              user.displayName ?? 'user_${user.uid.substring(0, 5)}',
              email: user.email ?? '',
              phoneNumber: user.phoneNumber,
              id: user.uid,
            );

            // Double check user hasn't changed/logged out during the async createPlayer call
            if (auth.currentUser?.uid != listenerTargetUid) return;

            Utilities.debugPrintWithCallerInfo(
                'Auto-created Firestore profile: ${newUserProfile.id}');

            // Sync the photoURL if available
            if (user.photoURL != null) {
              newUserProfile.avatarImageLocation = user.photoURL;
            }

            await login(newUserProfile);
          }
        }
      }
    });
  }

  Future<Player?> refreshPendingClaim() async {
    final user = auth.currentUser;
    if (user == null) {
      return null;
    }

    await user.reload();
    final refreshedUser = auth.currentUser ?? user;
    final claimedPlayer = await Player.claimPlayerForVerifiedAuthUser(
      uid: refreshedUser.uid,
      email: refreshedUser.email,
      emailVerified: refreshedUser.emailVerified,
      phoneNumber: refreshedUser.phoneNumber,
    );
    if (claimedPlayer != null) {
      await login(claimedPlayer);
      return claimedPlayer;
    }

    _pendingClaimPlayer = await Player.getPlayerByContactFromDB(
      refreshedUser.email,
      refreshedUser.phoneNumber,
    );
    notifyListeners();
    return null;
  }
}

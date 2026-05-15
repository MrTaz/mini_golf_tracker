import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  List<Player> players = [];
  
  // For testing purposes
  @visibleForTesting
  void resetForTesting() {
    _loggedInUser = null;
    players = [];
    _auth = null;
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }

  set loggedInUser(Player? player) {
    _loggedInUser = player;
    notifyListeners();
  }

  Future<void> login(Player player) async {
    _loggedInUser = player;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("email", player.email!);
    await prefs.setString("loggedInUser", jsonEncode(player));
    notifyListeners();
  }

  Future<void> logout() async {
    await auth.signOut();
    _loggedInUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("email");
    await prefs.remove("loggedInUser");
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
        if (_loggedInUser != null) {
          _loggedInUser = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove("email");
          await prefs.remove("loggedInUser");
          notifyListeners();
        }
      } else {
        // If Firebase says we are logged in, but our local state is empty or different,
        // try to fetch the player profile using the UID.
        if (_loggedInUser == null || _loggedInUser!.id != user.uid) {
          Player? player = await Player.fetchPlayerFromDatabase(user.uid);
          
          // Verify we are still looking at the same user before updating state
          if (auth.currentUser?.uid != listenerTargetUid) return;

          if (player != null) {
            // Update avatar if provided by Firebase and not set in player profile
            if (user.photoURL != null && player.avatarImageLocation != user.photoURL) {
              player.avatarImageLocation = user.photoURL;
            }
            await login(player);
          } else {
            // New user from social login (like Google) - create their profile
            Utilities.debugPrintWithCallerInfo('Creating new player profile for social user: ${user.email}');
            Utilities.debugPrintWithCallerInfo('No Firestore profile found for user ${user.email}. Creating one now...');
          
            final newUserProfile = await Player.createPlayer(
              user.displayName ?? 'New User',
              user.displayName ?? 'user_${user.uid.substring(0, 5)}',
              email: user.email,
              id: user.uid, // Use Firebase UID as Firestore Document ID
            );
          
            // Double check user hasn't changed/logged out during the async createPlayer call
            if (auth.currentUser?.uid != listenerTargetUid) return;

            Utilities.debugPrintWithCallerInfo('Auto-created Firestore profile: ${newUserProfile.id}');
            
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
}

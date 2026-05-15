import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() => _instance;

  UserProvider._internal();

  FirebaseAuth? _auth;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  // For testing purposes
  void setAuthInstanceForTesting(FirebaseAuth instance) {
    _auth = instance;
  }

  Player? _loggedInUser;
  Player? get loggedInUser => _loggedInUser;
  List<Player> players = [];

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
    auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        if (_loggedInUser != null) {
          _loggedInUser = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove("email");
          await prefs.remove("loggedInUser");
          notifyListeners();
        }
      } else {
        // If Firebase says we are logged in, but our local state is empty,
        // try to fetch the player profile.
        if (_loggedInUser == null || _loggedInUser!.email != user.email) {
          final player = await Player.getPlayerByEmailFromDB(user.email!);
          if (player != null) {
            // Update avatar if provided by Firebase and not set in player profile
            if (user.photoURL != null && player.avatarImageLocation != user.photoURL) {
              player.avatarImageLocation = user.photoURL;
              // Ideally we should save this back to DB, but for now we update local state
              // To ensure it persists, we can add a method to update player profile
            }
            await login(player);
          }
        }
      }
    });
  }
}

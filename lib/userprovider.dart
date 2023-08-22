import 'package:mini_golf_tracker/player.dart';

class UserProvider {
  factory UserProvider() => _instance;

  UserProvider._internal();

  Player? loggedInUser; // Replace User with your actual user model

  static final UserProvider _instance = UserProvider._internal();
}

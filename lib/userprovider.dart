import 'package:mini_golf_tracker/player.dart';

class UserProvider {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() => _instance;

  Player? loggedInUser; // Replace User with your actual user model

  UserProvider._internal();
}

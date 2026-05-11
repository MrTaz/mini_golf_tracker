import 'package:mini_golf_tracker/player.dart';

class UserProvider {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() => _instance;

  UserProvider._internal();

  Player? loggedInUser;
  List<Player> players = [];
}

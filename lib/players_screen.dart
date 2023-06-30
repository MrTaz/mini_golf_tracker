import 'package:flutter/material.dart';

import 'player.dart';
import 'player_create_screen.dart';
import 'players_list_screen.dart';

class PlayersScreen extends StatefulWidget {
  PlayersScreen({Key? key}) : super(key: key);

  @override
  _PlayersScreenState createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final List<Player> players = Player.getAllPlayers();
  final List<Player> selectedPlayers = [];
  bool showNewPlayerForm = false;
  bool showCloseButton = false;

  void fabPressed() {
    setState(() {
      showNewPlayerForm = true;
      showCloseButton = true;
    });
  }

  void savePlayer() {
    setState(() {
      showNewPlayerForm = false;
      showCloseButton = false;
    });
  }

  void closePlayerCreateScreen() {
    setState(() {
      showNewPlayerForm = false;
      showCloseButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: showNewPlayerForm
            ? PlayerCreateScreen(players: players, onSavePlayer: savePlayer)
            : Column(
                children: <Widget>[
                  ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(0.8),
                    itemCount: players.length,
                    itemBuilder: (BuildContext context, int index) {
                      return PlayerListItem(key: Key('counter-$index'), player: players[index]);
                    },
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCloseButton ? closePlayerCreateScreen : fabPressed,
        child: showCloseButton ? const Icon(Icons.close) : const Icon(Icons.person_add),
      ),
    );
  }
}

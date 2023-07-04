import 'package:flutter/material.dart';

import 'player.dart';
import 'player_create_screen.dart';
import 'players_list_screen.dart';

class PlayersScreen extends StatefulWidget {
  PlayersScreen({Key? key, this.creatingGame: false}) : super(key: key);
  final bool? creatingGame;

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

  _addPlayers() {
    // You can do anything with the selected players here
    Navigator.pop(context, selectedPlayers);
  }

  _handlePlayerSelection(Player player) {
    setState(() {
      if (selectedPlayers.contains(player)) {
        selectedPlayers.remove(player);
      } else {
        selectedPlayers.add(player);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.creatingGame!)
          ? AppBar(
              title: const Text('Select Players'),
            )
          : null,
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: showNewPlayerForm
                ? PlayerCreateScreen(players: players, onSavePlayer: savePlayer)
                : Column(
                    children: <Widget>[
                      ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(0.8),
                        itemCount: players.length,
                        itemBuilder: (BuildContext context, int index) {
                          bool isSelected = selectedPlayers.contains(players[index]);
                          return PlayerListItem(
                            key: Key('counter-$index'),
                            player: players[index],
                            creatingGame: widget.creatingGame,
                            onPlayerSelected: _handlePlayerSelection,
                            isSelected: isSelected,
                          );
                        },
                      ),
                      (widget.creatingGame!)
                          ? ElevatedButton(
                              onPressed: _addPlayers,
                              child: const Text('Add selected players to game.'),
                            )
                          : const SizedBox(height: 16.0),
                    ],
                  ),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: showCloseButton ? closePlayerCreateScreen : fabPressed,
        child: showCloseButton ? const Icon(Icons.close) : const Icon(Icons.person_add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/userprovider.dart';

import 'player.dart';
import 'player_create_screen.dart';
import 'player_game_info.dart';
import 'players_list_screen.dart';
import 'utilities.dart';

class PlayersScreen extends StatefulWidget {
  final bool? creatingGame;
  final List<PlayerGameInfo?>? currentlySelectedPlayers;

  const PlayersScreen({Key? key, this.creatingGame = false, this.currentlySelectedPlayers}) : super(key: key);

  @override
  PlayersScreenState createState() => PlayersScreenState();
}

class PlayersScreenState extends State<PlayersScreen> {
  final Player? loggedInUser = UserProvider().loggedInUser;
  final List<Player> players = [];
  final List<Player> selectedPlayers = [];
  bool showNewPlayerForm = false;
  bool showCloseButton = false;

  void fabPressed() {
    setState(() {
      showNewPlayerForm = true;
      showCloseButton = true;
    });
  }

  void closePlayerCreateScreen() {
    setState(() {
      showNewPlayerForm = false;
      showCloseButton = false;
    });
  }

  void savePlayer() {
    setState(() {
      showNewPlayerForm = false;
      showCloseButton = false;
    });
  }

  _addPlayers() {
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

  _initializePlayers() {
    if (widget.currentlySelectedPlayers != null && widget.currentlySelectedPlayers!.isNotEmpty) {
      Iterable<PlayerGameInfo> passedInSelectedPlayers =
          widget.currentlySelectedPlayers!.where((player) => player != null).cast<PlayerGameInfo>();

      for (PlayerGameInfo passedInSelectedPlayer in passedInSelectedPlayers) {
        players.addAll(loggedInUser!.getAllPlayerFriends());
        Player? lookedUpPlayer = loggedInUser!.getPlayerFriendById(passedInSelectedPlayer.playerId);
        if (lookedUpPlayer != null) {
          selectedPlayers.add(lookedUpPlayer);
        }
      }
    }else{
      players.addAll(loggedInUser!.getAllPlayerFriends());
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: (widget.creatingGame!)
          ? AppBar(
              title: const Text('Select Players'),
            )
          : null,
      body: Stack(
        children: [
          Utilities.backdropImageContinerWidget(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                        return _buildPlayerListItem(index, isSelected);                              
                      },
                    ),
                    (widget.creatingGame!)
                      ? ElevatedButton(
                          onPressed: _addPlayers,
                          child: const Text('Add selected players to game.'),
                        )
                      : const SizedBox(height: 16.0),
                  ],
                )
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCloseButton ? closePlayerCreateScreen : fabPressed,
        child: showCloseButton ? const Icon(Icons.close) : const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildPlayerListItem(int index, bool isSelected){
    return PlayerListItem(
      key: Key('counter-$index'),
      player: players[index],
      creatingGame: widget.creatingGame,
      onPlayerSelected: _handlePlayerSelection,
      isSelected: isSelected,
    );
  }

}


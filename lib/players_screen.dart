import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/userprovider.dart';

import 'player.dart';
import 'player_create_screen.dart';
import 'player_game_info.dart';
import 'players_list_screen.dart';
import 'utilities.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen(
      {super.key, this.creatingGame = false, this.currentlySelectedPlayers});

  final bool? creatingGame;
  final List<PlayerGameInfo?>? currentlySelectedPlayers;

  @override
  PlayersScreenState createState() => PlayersScreenState();
}

class PlayersScreenState extends State<PlayersScreen> {
  final Player? loggedInUser = UserProvider().loggedInUser;
  final List<Player> players = [];
  final List<Player> selectedPlayers = [];
  bool showCloseButton = false;
  bool showNewPlayerForm = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (loggedInUser == null) {
      await Player.loadLocalGuestPlayers();
    }
    if (!mounted) return;
    setState(_initializePlayers);
  }

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
      players
        ..clear()
        ..addAll(loggedInUser?.getAllPlayerFriends() ?? Player.players);
      showNewPlayerForm = false;
      showCloseButton = false;
    });
  }

  void _addPlayers() {
    Navigator.pop(context, selectedPlayers);
  }

  void _handlePlayerSelection(Player player) {
    setState(() {
      if (selectedPlayers.contains(player)) {
        selectedPlayers.remove(player);
      } else {
        selectedPlayers.add(player);
      }
    });
  }

  void _initializePlayers() {
    final availablePlayers =
        loggedInUser?.getAllPlayerFriends() ?? Player.players;

    if (widget.currentlySelectedPlayers != null &&
        widget.currentlySelectedPlayers!.isNotEmpty) {
      Iterable<PlayerGameInfo> passedInSelectedPlayers = widget
          .currentlySelectedPlayers!
          .where((player) => player != null)
          .cast<PlayerGameInfo>();

      players.addAll(availablePlayers);
      for (PlayerGameInfo passedInSelectedPlayer in passedInSelectedPlayers) {
        Player? lookedUpPlayer;
        for (final player in availablePlayers) {
          if (player.id == passedInSelectedPlayer.playerId) {
            lookedUpPlayer = player;
            break;
          }
        }
        if (lookedUpPlayer != null &&
            !selectedPlayers.contains(lookedUpPlayer)) {
          selectedPlayers.add(lookedUpPlayer);
        }
      }
    } else {
      players.addAll(availablePlayers);
    }
  }

  Widget _buildPlayerListItem(int index, bool isSelected) {
    return PlayerListItem(
      key: Key('counter-$index'),
      player: players[index],
      creatingGame: widget.creatingGame,
      onPlayerSelected: _handlePlayerSelection,
      isSelected: isSelected,
    );
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
                    ? PlayerCreateScreen(
                        players: players, onSavePlayer: savePlayer)
                    : Column(
                        children: <Widget>[
                          ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(0.8),
                            itemCount: players.length,
                            itemBuilder: (BuildContext context, int index) {
                              bool isSelected =
                                  selectedPlayers.contains(players[index]);
                              return _buildPlayerListItem(index, isSelected);
                            },
                          ),
                          (widget.creatingGame!)
                              ? ElevatedButton(
                                  onPressed: _addPlayers,
                                  child: const Text(
                                      'Add selected players to game.'),
                                )
                              : const SizedBox(height: 16.0),
                        ],
                      )),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCloseButton ? closePlayerCreateScreen : fabPressed,
        child: showCloseButton
            ? const Icon(Icons.close)
            : const Icon(Icons.person_add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';

import '../../data/models/player.dart';
import 'player_create_screen.dart';
import '../../../gameplay/data/models/player_game_info.dart';
import 'players_list_screen.dart';
import '../../../../core/utils/utilities.dart';
import '../../../../core/animations/asset_bouncy_animation.dart';
import '../../../../core/config/asset_golf_ball_path.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen(
      {super.key, this.creatingGame = false, this.currentlySelectedPlayers});

  final bool? creatingGame;
  final List<dynamic>? currentlySelectedPlayers;

  @override
  PlayersScreenState createState() => PlayersScreenState();
}

class PlayersScreenState extends State<PlayersScreen> {
  final Player? loggedInUser = UserProvider().loggedInUser;
  final List<Player> players = [];
  final List<Player> selectedPlayers = [];
  bool showCloseButton = false;
  bool showNewPlayerForm = false;
  bool _isLoading = true;
  bool _isOffline = false;

  @visibleForTesting
  void setOfflineForTesting(bool value) {
    setState(() {
      _isOffline = value;
    });
  }

  @visibleForTesting
  void clearPlayersForTesting() {
    setState(() {
      players.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });
    try {
      if (loggedInUser == null) {
        await Player.loadLocalGuestPlayers();
      } else {
        await loggedInUser!.loadUserPlayers();
      }
    } catch (e) {
      _isOffline = true;
      Utilities.debugPrintWithCallerInfo("Error loading players: $e");
    }
    if (!mounted) return;
    setState(() {
      _initializePlayers();
      _isLoading = false;
    });
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

  void _clearAll() {
    setState(() {
      selectedPlayers.clear();
    });
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
    final availablePlayers = _playersWithCreatorProfile();

    if (widget.currentlySelectedPlayers != null &&
        widget.currentlySelectedPlayers!.isNotEmpty) {
      players.addAll(availablePlayers);
      for (final passedInPlayer in widget.currentlySelectedPlayers!) {
        if (passedInPlayer == null) continue;

        Player? lookedUpPlayer;
        if (passedInPlayer is PlayerGameInfo) {
          for (final player in availablePlayers) {
            if (player.id == passedInPlayer.playerId) {
              lookedUpPlayer = player;
              break;
            }
          }
        } else if (passedInPlayer is Player) {
          for (final player in availablePlayers) {
            if (player.id == passedInPlayer.id) {
              lookedUpPlayer = player;
              break;
            }
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

  List<Player> _playersWithCreatorProfile() {
    final sourcePlayers = loggedInUser?.getAllPlayerFriends() ?? Player.players;
    final orderedPlayers = List<Player>.from(sourcePlayers);
    final existingGuestProfile = orderedPlayers
        .where((player) => player.id == 'guest')
        .cast<Player?>()
        .firstOrNull;
    final creatorProfile = loggedInUser ??
        existingGuestProfile ??
        Player(
          id: 'guest',
          playerName: 'Guest',
          nickname: 'Guest Scorekeeper',
          ownerId: 'guest',
          totalScore: 0,
        );
    orderedPlayers.removeWhere((player) => player.id == creatorProfile.id);
    return [creatorProfile, ...orderedPlayers];
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
      appBar: (widget.creatingGame == true)
          ? AppBar(
              title: const Text('Select Players'),
              actions: [
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear All'),
                ),
              ],
            )
          : (loggedInUser == null
              ? AppBar(title: const Text('Friends'))
              : null),
      body: Stack(
        children: [
          Utilities.backdropImageContinerWidget(),
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 40.0),
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20.0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.teal.shade700.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: BouncyAnimation(
                          duration: const Duration(seconds: 1),
                          lift: 50,
                          ratio: 0.25,
                          child: CustomPaint(
                            painter: GolfBallPainter(),
                            child: const SizedBox(width: 60, height: 60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Gathering Players...',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.teal.shade100,
                        color: Colors.teal.shade700,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: showNewPlayerForm
                      ? PlayerCreateScreen(
                          players: players, onSavePlayer: savePlayer)
                      : Column(
                          children: <Widget>[
                            if (_isOffline) _buildOfflineBanner(),
                            if (players.isEmpty && _isOffline)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 40.0, horizontal: 16.0),
                                child: Center(
                                  child: Text(
                                    "We couldn't load your friends. Please check your internet connection or play offline with guest players.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(0.8),
                                itemCount: players.length,
                                itemBuilder: (BuildContext context, int index) {
                                  bool isSelected =
                                      selectedPlayers.contains(players[index]);
                                  return _buildPlayerListItem(
                                      index, isSelected);
                                },
                              ),
                            const SizedBox(height: 16.0),
                          ],
                        )),
            )
        ],
      ),
      bottomNavigationBar: (widget.creatingGame! &&
              !showNewPlayerForm &&
              !_isLoading)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _addPlayers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                  child: const Text('Add selected players to game.',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: showCloseButton ? closePlayerCreateScreen : fabPressed,
        child: showCloseButton
            ? const Icon(Icons.close)
            : const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              "Offline mode: showing cached friends. Connect to the internet to sync cloud changes.",
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

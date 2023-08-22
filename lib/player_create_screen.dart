import 'package:flutter/material.dart';

import 'player.dart';
import 'player_form_widget.dart';

class PlayerCreateScreen extends StatefulWidget {
  const PlayerCreateScreen({super.key, required this.players, required this.onSavePlayer});

  final VoidCallback onSavePlayer;
  final List<Player> players;

  @override
  PlayerCreateScreenState createState() => PlayerCreateScreenState();
}

class PlayerCreateScreenState extends State<PlayerCreateScreen> {
  late Player newPlayer;

  @override
  void initState() {
    super.initState();
    newPlayer = Player(id: 0, playerName: '', nickname: '', ownerId: 0, totalScore: 0);
  }

  void savePlayer() {
    widget.onSavePlayer(); // Notify the parent widget that a player has been saved
    // Player.empty().addPlayerFriend(newPlayer);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PlayerForm(
        player: newPlayer,
        allowEditing: true,
        onSaveChanges: savePlayer,
        editingOrAdding: "Add",
      ),
    );
  }
}

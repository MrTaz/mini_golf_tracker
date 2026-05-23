import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'player.dart';
import 'player_form_widget.dart';

class PlayerCreateScreen extends StatefulWidget {
  const PlayerCreateScreen(
      {super.key, required this.players, required this.onSavePlayer});

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
    newPlayer = Player(
      id: const Uuid().v4(),
      playerName: '',
      nickname: '',
      ownerId: '',
      totalScore: 0,
    );
  }

  void savePlayer() {
    widget
        .onSavePlayer(); // Notify the parent widget that a player has been saved
    // Player.empty().addPlayerFriend(newPlayer);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: PlayerForm(
          player: newPlayer,
          allowEditing: true,
          onSaveChanges: savePlayer,
          editingOrAdding: "Add",
        ),
      ),
    );
  }
}

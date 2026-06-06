import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/player.dart';
import '../widgets/player_form_widget.dart';

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
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade700,
                  child: const Icon(Icons.person_add_alt_1),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'New Player',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PlayerForm(
              player: newPlayer,
              allowEditing: true,
              onSaveChanges: savePlayer,
              editingOrAdding: "Add",
            ),
          ],
        ),
      ),
    );
  }
}

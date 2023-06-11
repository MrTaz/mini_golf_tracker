import 'package:flutter/material.dart';

import 'player_game_info.dart';

class PlayerScoreCard extends StatefulWidget {
  final List<PlayerGameInfo> sortedPlayerScores;

  const PlayerScoreCard({Key? key, required this.sortedPlayerScores}) : super(key: key);

  @override
  PlayerScoreCardState createState() => PlayerScoreCardState();
}

class PlayerScoreCardState extends State<PlayerScoreCard> {
  List<int> selectedPlayerIds = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final gameInfo in widget.sortedPlayerScores)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedPlayerIds.contains(gameInfo.playerId)) {
                        selectedPlayerIds.remove(gameInfo.playerId);
                      } else {
                        selectedPlayerIds.add(gameInfo.playerId);
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Text('Player ${gameInfo.playerId}'),
                      if (selectedPlayerIds.contains(gameInfo.playerId))
                        Column(
                          children: [
                            for (final score in gameInfo.scores) Text(score.toString()),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

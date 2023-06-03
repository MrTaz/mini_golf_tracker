import 'package:flutter/material.dart';

import 'player.dart';
import 'playerListItem.dart';

class PlayersScreen extends StatelessWidget {
  PlayersScreen({Key? key}) : super(key: key);

  final List<Player> players = [
    Player(id: 1, playerName: "Will", nickname: "Dad", totalScore: 50),
    Player(id: 2, playerName: "Mandi", nickname: "Mom", totalScore: 51)
  ];
  final List<Player> selectedPlayers = [];

  void fabPressed() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.8),
              itemCount: players.length,
              itemBuilder: (BuildContext context, int index) {
                return PlayerListItem(
                    key: Key('counter-$index'), player: players[index]);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: fabPressed, child: const Icon(Icons.person_add)),
    );
  }
}

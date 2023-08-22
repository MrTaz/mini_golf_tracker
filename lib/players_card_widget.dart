import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/userprovider.dart';

import 'player.dart';
import 'player_game_info.dart';
import 'player_profile_widget.dart';

class PlayersCard extends StatefulWidget {
  const PlayersCard(
      {Key? key, this.cardTitle, this.sortedPlayerIds, this.sortedPlayerScores, this.onTap, this.onPlayerCardTap})
      : super(key: key);

  final String? cardTitle;
  final ValueChanged<bool>? onPlayerCardTap;
  final ValueChanged<Player>? onTap;
  final List<int>? sortedPlayerIds;
  final List<PlayerGameInfo>? sortedPlayerScores;

  @override
  PlayersCardState createState() => PlayersCardState();
}

class PlayersCardState extends State<PlayersCard> {
  Player? loggedInUser = UserProvider().loggedInUser;
  List<Player> playerFriends = [];
  List<int> scoresToShow = [];
  List<int> selectedPlayerIds = [];
  List<Player> sortedPlayers = [];

  @override
  void initState() {
    super.initState();
    playerFriends = loggedInUser!.getAllPlayerFriends();
    sortedPlayers = widget.sortedPlayerIds != null && widget.sortedPlayerIds!.isNotEmpty
        ? (widget.sortedPlayerIds!.map((id) => playerFriends.firstWhere((player) => player.id == id)).toList()
          ..sort((a, b) => widget.sortedPlayerIds!.indexOf(a.id).compareTo(widget.sortedPlayerIds!.indexOf(b.id))))
        : (List.from(playerFriends)
          ..sort((a, b) {
            if (a.totalScore != b.totalScore) {
              if (a.totalScore == 0) {
                return 1; // Player a has total score 0, place it after player b
              } else if (b.totalScore == 0) {
                return -1; // Player b has total score 0, place it after player a
              } else {
                return a.totalScore.compareTo(b.totalScore);
              }
            } else {
              return a.id.compareTo(b.id);
            }
          }));
  }

  List<Widget> getPlayerCards(BuildContext context) {
    List<Widget> playerCards = [];
    for (var i = 0; i < sortedPlayers.length; i++) {
      var player = sortedPlayers[i];
      final bool isSelected = selectedPlayerIds.contains(player.id);
      playerCards.add(GestureDetector(
        onTap: widget.onTap != null
            ? () => {
                  widget.onTap!(player),
                  setState(() {
                    if (selectedPlayerIds.contains(player.id)) {
                      selectedPlayerIds.remove(player.id);
                    } else {
                      selectedPlayerIds.add(player.id);
                    }
                  })
                }
            : null,
        child: PlayerProfileWidget(player: player, rank: i, isSelected: isSelected),
      ));
    }
    return playerCards;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
            onTap: widget.onPlayerCardTap != null ? () => {widget.onPlayerCardTap!(true)} : null,
            child: Card(
                elevation: 6,
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: <Widget>[
                      ListTile(
                        title: Text(widget.cardTitle ?? "Friends"),
                      ),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal, child: Row(children: getPlayerCards(context))),
                    ])))));
  }
}

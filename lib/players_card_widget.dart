import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'gravatar_image_view.dart';
import 'player.dart';
import 'player_game_info.dart';

class PlayersCard extends StatefulWidget {
  final List<int>? sortedPlayerIds;
  final String? cardTitle;
  final List<PlayerGameInfo>? sortedPlayerScores;
  final ValueChanged<Player>? onTap;

  const PlayersCard({Key? key, this.cardTitle, this.sortedPlayerIds, this.sortedPlayerScores, this.onTap})
      : super(key: key);

  @override
  PlayersCardState createState() => PlayersCardState();
}

class PlayersCardState extends State<PlayersCard> {
  List<int> selectedPlayerIds = [];
  List<int> scoresToShow = [];
  List<Player> sortedPlayers = [];
  List<Player> playerFriends = Player.getAllPlayers();

  @override
  void initState() {
    super.initState();
    playerFriends = Player.getAllPlayers();
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

  @override
  Widget build(BuildContext context) {
    return Center(
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
                ]))));
  }

  List<Widget> getPlayerCards(BuildContext context) {
    List<Widget> playerCards = [];

    // sortedPlayers.forEach((element) => debugPrint('Sorted player ids: ${widget.sortedPlayerIds} ${element.toJson()}'));

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
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: getRankBorderColor(i), width: 2.0),
              color: Colors.white38,
              image: DecorationImage(
                  alignment: const Alignment(0.8, 0.8), fit: BoxFit.none, scale: 3, image: getRankBackImg(i)),
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white10,
                  blurRadius: 4,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(4),
            height: MediaQuery.of(context).size.height * 0.15,
            width: MediaQuery.of(context).size.width * 0.2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                    child: CircleAvatar(
                        backgroundColor: Colors.teal, child: ClipOval(child: GravatarImageView(email: player.email!)))),
                const SizedBox(
                  height: 10.0,
                ),
                Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(player.nickname,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                            )))),
                if (isSelected)
                  const Chip(
                    label: Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          )));
    }
    return playerCards;
  }

  Color getRankBorderColor(int currentRank) {
    switch (currentRank) {
      case 0:
        return const Color(0xFFDAA520);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFECC5C0);
      default:
        return const Color(0xffeeeeee);
    }
  }

  ImageProvider getRankBackImg(int currentRank) {
    switch (currentRank) {
      case 0:
        return Image.asset("assets/images/rank1.png").image;
      case 1:
        return Image.asset("assets/images/rank2.png").image;
      case 2:
        return Image.asset("assets/images/rank3.png").image;
      default:
        return Image.memory(kTransparentImage).image;
      // return Image.asset("assets/images/loggedin_background_2.png");
    }
  }
}

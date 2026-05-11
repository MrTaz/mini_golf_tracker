import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';

class PastGameListItem extends StatefulWidget {
  const PastGameListItem({
    super.key,
    required this.pastGame,
    this.onPastGameCardTap,
    this.isSelected = false,
  });

  final bool isSelected;
  final ValueChanged<bool>? onPastGameCardTap;
  final Game pastGame;

  @override
  PastGameListItemState createState() => PastGameListItemState();
}

class PastGameListItemState extends State<PastGameListItem> {
  bool isSelected = false;
  Player? loggedInUser = UserProvider().loggedInUser;

  @override
  void initState() {
    super.initState();
    _initializeCurrentPastGame();
    isSelected = widget.isSelected;
  }

  Future<void> _initializeCurrentPastGame() async {}

  Widget _buildPastGameListItem() {
    return Card(
      color: const Color.fromARGB(207, 255, 255, 255),
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          ListTile(
            title: widget.pastGame.completedTime != null
                ? FutureBuilder<String>(
                    future: Utilities.formatStartTime(widget.pastGame.completedTime!),
                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                      String timeText;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        timeText = "Loading...";
                      } else if (snapshot.hasData) {
                        timeText = "Played ${snapshot.data}";
                      } else {
                        timeText = ""; // Or handle error
                      }
                      return Text(
                        "${widget.pastGame.name} - $timeText",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
                      );
                    },
                  )
                : Text(
                    widget.pastGame.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
                  ),
            subtitle: Text(
              'Course: ${widget.pastGame.course.name}, (${widget.pastGame.course.numberOfHoles} holes) - ${widget.pastGame.players.length} players, Winner: ${loggedInUser!.getPlayerFriendById(widget.pastGame.getWinner().playerId)!.nickname}',
              // style: const TextStyle(
              //   fontSize: 8.0
              // )
            ),
            selected: isSelected,
            iconColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
              return states.contains(WidgetState.selected) ? Colors.green : Colors.teal;
            }),
            onTap: widget.onPastGameCardTap != null
                ? () => {widget.onPastGameCardTap!(true)}
                : () => {
                      setState(() {
                        isSelected = !isSelected;
                      })
                    },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPastGameListItem();
  }
}

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';

class PastGameListItem extends StatefulWidget {
  const PastGameListItem({
    Key? key,
    required this.pastGame,
    this.onPastGameCardTap,
    this.isSelected = false,
  }) : super(key: key);

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
            title: Text(
                "${widget.pastGame.name} - ${(widget.pastGame.completedTime != null) ? "Played ${Utilities.formatStartTime(widget.pastGame.completedTime!)}" : ""}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic)),
            subtitle: Text(
              'Course: ${widget.pastGame.course.name}, (${widget.pastGame.course.numberOfHoles} holes) - ${widget.pastGame.players.length} players, Winner: ${loggedInUser!.getPlayerFriendById(widget.pastGame.getWinner().playerId)!.nickname}',
              // style: const TextStyle(
              //   fontSize: 8.0
              // )
            ),
            selected: isSelected,
            iconColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
              return states.contains(MaterialState.selected) ? Colors.green : Colors.teal;
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

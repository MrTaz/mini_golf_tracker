import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gravatar_image_view.dart';
import 'player.dart';
import 'player_form_widget.dart';

class PlayerListItem extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final Player player;
  final bool? creatingGame;
  final bool isSelected;
  final ValueChanged<Player>? onPlayerSelected;
  final int? listOrderNumber;
  final VoidCallback? onRemove;

  const PlayerListItem(
      {Key? key,
      required this.player,
      this.onChanged,
      this.creatingGame,
      this.onPlayerSelected,
      this.isSelected = false,
      this.listOrderNumber,
      this.onRemove})
      : super(key: key);

  @override
  _PlayerListItemState createState() => _PlayerListItemState();
}

class _PlayerListItemState extends State<PlayerListItem> {
  bool isSelected = false;
  final bool _enabled = true;
  bool _allowEditing = false;
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    isSelected = widget.isSelected;
  }

  Future<void> loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _allowEditing = widget.player.ownerId == Player.getPlayerByEmail(prefs.getString("email") ?? "")?.id;
    });
  }

  void toggleDropdown() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
    });
  }

  String getPlayerPositionSuffix(int position) {
    if (position % 10 == 1 && position % 100 != 11) {
      return "st";
    } else if (position % 10 == 2 && position % 100 != 12) {
      return "nd";
    } else if (position % 10 == 3 && position % 100 != 13) {
      return "rd";
    } else {
      return "th";
    }
  }

  @override
  Widget build(BuildContext context) {
    // final orderNumberText = widget.listOrderNumber != null
    //     ? Text(
    //         "Plays: ${widget.listOrderNumber}${getPlayerPositionSuffix(widget.listOrderNumber!)}",
    //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    //       )
    //     : SizedBox.shrink();
    Widget playerProfileCircleIcon = FittedBox(
        child: CircleAvatar(
            backgroundColor: Colors.teal, child: ClipOval(child: GravatarImageView(email: widget.player.email!))));
    Widget leadingWidget;
    if (widget.listOrderNumber != null) {
      leadingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.listOrderNumber.toString() + getPlayerPositionSuffix(widget.listOrderNumber!)),
          SizedBox(width: 8.0),
          playerProfileCircleIcon,
        ],
      );
    } else {
      leadingWidget = playerProfileCircleIcon;
    }

    return Card(
      child: Column(
        children: [
          // orderNumberText,
          ListTile(
            enabled: _enabled,
            selected: widget.isSelected,
            onTap: () {
              setState(() {
                // This is called when the user toggles the switch.
                isSelected = !isSelected;
              });
            },
            iconColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.green;
              }
              return Colors.teal;
            }),
            leading: leadingWidget,
            title: Text(widget.player.nickname),
            subtitle: Text(widget.player.playerName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_allowEditing)
                  GestureDetector(
                    onTap: toggleDropdown,
                    child: const Icon(Icons.edit),
                  ),
                const SizedBox(width: 8),
                if (widget.onRemove != null) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: widget.onRemove,
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.creatingGame == true)
                  Switch(
                    onChanged: (bool? value) {
                      setState(() {
                        isSelected = value!;
                      });
                      if (widget.onPlayerSelected != null) {
                        widget.onPlayerSelected!(widget.player);
                      }
                      // if (isSelected) {
                      //   // removePlayerFromGame(player);
                      // } else {
                      //   // addPlayerToGame(player);
                      // }
                    },
                    value: isSelected,
                  ),
              ],
            ),
          ),
          if (isDropdownOpen) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PlayerForm(
                player: widget.player,
                allowEditing: _allowEditing,
                editingOrAdding: "Edit",
                onSaveChanges: () {
                  // Save changes
                  setState(() {
                    isDropdownOpen = false;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

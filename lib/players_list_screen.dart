import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player.dart';
import 'player_form_widget.dart';

class PlayerListItem extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final Player player;
  final bool? creatingGame;
  final bool isSelected;
  final ValueChanged<Player>? onPlayerSelected;

  const PlayerListItem(
      {Key? key,
      required this.player,
      this.onChanged,
      this.creatingGame,
      this.onPlayerSelected,
      this.isSelected = false})
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
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
              return Colors.teal.shade50;
            }),
            leading: const Icon(Icons.person),
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

import 'package:flutter/material.dart';

import 'player.dart';

class PlayerListItem extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final Player player;

  const PlayerListItem({super.key, required this.player, this.onChanged});

  @override
  _PlayerListItem createState() => _PlayerListItem();
}

class _PlayerListItem extends State<PlayerListItem> {
  bool isSelected = false;
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: _enabled,
        selected: isSelected,
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
        trailing: Switch(
          onChanged: (bool? value) {
            setState(() {
              isSelected = value!;
            });
            if (isSelected) {
              // removePlayerFromGame(player);
            } else {
              // addPlayerToGame(player);
            }
          },
          value: isSelected,
        ),
      ),
    );
  }
}

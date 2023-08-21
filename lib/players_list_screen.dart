import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/userprovider.dart';
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
  PlayerListItemState createState() => PlayerListItemState();
}

class PlayerListItemState extends State<PlayerListItem> {
  bool isSelected = false;
  final bool _enabled = true;
  bool _allowEditing = false;
  bool isDropdownOpen = false;
  final Player? loggedInUser = UserProvider().loggedInUser;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    isSelected = widget.isSelected;
  }

  Future<void> loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _allowEditing = widget.player.ownerId == loggedInUser!.getPlayerFriendByEmail(prefs.getString("email") ?? "")?.id;
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
    return _buildPlayerListItem();
  }

  Widget _buildPlayerListItem() {
    return Card(
      child: Column(
        children: [
          // orderNumberText,
          ListTile(
              title: Text(widget.player.nickname),
              subtitle: Text(widget.player.playerName),
              leading: _buildLeadingWidget(),
              enabled: _enabled,
              selected: widget.isSelected,
              iconColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                return states.contains(MaterialState.selected) ? Colors.green : Colors.teal;
              }),
              onTap: () {
                setState(() {
                  // This is called when the user toggles the switch.
                  isSelected = !isSelected;
                });
              },
              trailing: _buildTrailingIcons()),
          _buildListItemDropDownEdit()
        ],
      ),
    );
  }

  Widget _buildLeadingWidget() {
    Widget leadingWidget;
    if (widget.listOrderNumber != null) {
      leadingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.listOrderNumber.toString() + getPlayerPositionSuffix(widget.listOrderNumber!)),
          const SizedBox(width: 8.0),
          _buildPlayerProfileCircleIcon(),
        ],
      );
    } else {
      leadingWidget = _buildPlayerProfileCircleIcon();
    }
    return leadingWidget;
  }

  Widget _buildPlayerProfileCircleIcon() {
    return FittedBox(
        child: CircleAvatar(
            backgroundColor: Colors.teal, child: ClipOval(child: GravatarImageView(email: widget.player.email!))));
  }

  Widget _buildTrailingIcons() {
    return Row(
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
            value: isSelected,
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
          ),
      ],
    );
  }

  Widget _buildListItemDropDownEdit() {
    if (isDropdownOpen) {
      return Column(children: <Widget>[
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
      ]);
    } else {
      return const SizedBox(width: 0);
    }
  }
}

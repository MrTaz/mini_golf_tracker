import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/userprovider.dart';

import 'player.dart';
import 'player_form_widget.dart';
import 'player_avatar_widget.dart';

class PlayerListItem extends StatefulWidget {
  const PlayerListItem(
      {super.key,
      required this.player,
      this.onChanged,
      this.creatingGame,
      this.onPlayerSelected,
      this.isSelected = false,
      this.listOrderNumber,
      this.onRemove,
      this.showDragHandle = false});

  final bool? creatingGame;
  final bool showDragHandle;
  final bool isSelected;
  final int? listOrderNumber;
  final ValueChanged<String>? onChanged;
  final ValueChanged<Player>? onPlayerSelected;
  final VoidCallback? onRemove;
  final Player player;

  @override
  PlayerListItemState createState() => PlayerListItemState();
}

class PlayerListItemState extends State<PlayerListItem> {
  bool isDetailsOpen = false;
  bool isDropdownOpen = false;
  bool isSelected = false;
  final Player? loggedInUser = UserProvider().loggedInUser;

  bool _allowEditing = false;
  final bool _enabled = true;
  bool get _isOwner =>
      loggedInUser?.id != null && loggedInUser?.id == widget.player.id;
  String get _visiblePlayerName => !widget.player.shareName && !_isOwner
      ? widget.player.nickname
      : widget.player.playerName;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(covariant PlayerListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      setState(() {
        isSelected = widget.isSelected;
      });
    }
  }

  Future<void> loadCurrentUser() async {
    setState(() {
      if (loggedInUser == null) {
        _allowEditing = widget.player.ownerId == 'guest';
      } else {
        _allowEditing = widget.player.ownerId == loggedInUser!.id &&
            widget.player.claimedByUid == null;
      }
    });
  }

  void toggleDropdown() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
      if (isDropdownOpen) {
        isDetailsOpen = false;
      }
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

  Widget _buildPlayerListItem() {
    final children = [
      _buildReadOnlyDetails(),
      _buildListItemDropDownEdit(),
    ];
    return Card(
      elevation: 0,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: widget.creatingGame == true
          ? Column(
              children: [
                ListTile(
                  title: Text(widget.player.nickname),
                  subtitle: Text(_visiblePlayerName),
                  leading: _buildLeadingWidget(),
                  enabled: _enabled,
                  selected: widget.isSelected,
                  iconColor: _iconColor(),
                  onTap: _toggleGameSelection,
                  trailing: _buildTrailingIcons(),
                ),
                _buildListItemDropDownEdit(),
              ],
            )
          : ExpansionTile(
              key: ValueKey('$isDetailsOpen-$isDropdownOpen'),
              initiallyExpanded: isDetailsOpen || isDropdownOpen,
              onExpansionChanged: (value) {
                setState(() {
                  isDetailsOpen = value;
                  if (value) {
                    isDropdownOpen = false;
                  }
                });
              },
              title: Text(widget.player.nickname),
              subtitle: Text(_visiblePlayerName),
              leading: _buildLeadingWidget(),
              enabled: _enabled,
              iconColor: Colors.teal,
              collapsedIconColor: Colors.teal,
              trailing: _buildTrailingIcons(),
              children: children,
            ),
    );
  }

  WidgetStateColor _iconColor() {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      return states.contains(WidgetState.selected) ? Colors.green : Colors.teal;
    });
  }

  void _toggleGameSelection() {
    setState(() {
      isSelected = !isSelected;
    });
    if (widget.onPlayerSelected != null) {
      widget.onPlayerSelected!(widget.player);
    }
  }

  Widget _buildLeadingWidget() {
    Widget leadingWidget;
    if (widget.listOrderNumber != null) {
      leadingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.listOrderNumber.toString() +
              getPlayerPositionSuffix(widget.listOrderNumber!)),
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
    return FittedBox(child: PlayerAvatarWidget(player: widget.player));
  }

  Widget _buildTrailingIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_allowEditing)
          GestureDetector(
            onTap: toggleDropdown,
            child: Icon(isDropdownOpen ? Icons.close : Icons.edit),
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
            onChanged: (bool value) {
              setState(() {
                isSelected = value;
              });
              if (widget.onPlayerSelected != null) {
                widget.onPlayerSelected!(widget.player);
              }
            },
          ),
        if (widget.showDragHandle) const Icon(Icons.drag_handle),
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

  Widget _buildReadOnlyDetails() {
    if (widget.creatingGame == true || isDropdownOpen) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          _buildDetailRow(
              'Email',
              _sharedContactValue(
                  widget.player.email, widget.player.shareEmail)),
          _buildDetailRow(
              'Phone',
              _sharedContactValue(
                  widget.player.phoneNumber, widget.player.sharePhone)),
          _buildDetailRow('Total Score', widget.player.totalScore.toString()),
        ],
      ),
    );
  }

  String _sharedContactValue(String? value, bool isShared) {
    if (!isShared && !_isOwner) {
      return 'Hidden by user';
    }
    return value ?? 'Not provided';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayerListItem();
  }
}

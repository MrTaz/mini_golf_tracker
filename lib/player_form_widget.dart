import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/userprovider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import 'player.dart';

class PlayerForm extends StatefulWidget {
  final Player? player;
  final bool allowEditing;
  final VoidCallback onSaveChanges;
  final String editingOrAdding;

  const PlayerForm(
      {this.player, required this.allowEditing, required this.onSaveChanges, required this.editingOrAdding});

  @override
  _PlayerFormState createState() => _PlayerFormState();
}

class _PlayerFormState extends State<PlayerForm> {
  late TextEditingController _playerNameController;
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _statusController;
  // late Player currentUser;
  Player? currentUser = UserProvider().loggedInUser;
  bool isDuplicate = false;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    _playerNameController = TextEditingController(text: widget.player?.playerName ?? '');
    _nicknameController = TextEditingController(text: widget.player?.nickname ?? '');
    _emailController = TextEditingController(text: widget.player?.email ?? '');
    _phoneNumberController = TextEditingController(text: widget.player?.phoneNumber ?? '');
    _statusController = TextEditingController(text: widget.player?.status ?? '');
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.player != null;

  Future<void> loadCurrentUser() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   currentUser = Player.getPlayerByEmail(prefs.getString("email") ?? "")!;
    // });
  }

  bool validateRequiredFields() {
    if (_playerNameController.text.isEmpty || _nicknameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing required fields'),
            content: (_playerNameController.text.isEmpty)
                ? const Text("The Player's Name must be filled in.")
                : const Text("The Player's Nickname must be filled in."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return false;
    }
    return true;
  }

  void checkDuplicate() {
    // Check for duplicates before saving
    List<Player> allPlayers = currentUser!.getAllPlayerFriends();
    isDuplicate = allPlayers.any((player) =>
        player != widget.player &&
        (player.playerName == _playerNameController.text && player.nickname == _nicknameController.text));

    if (isDuplicate) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Duplicate Player'),
            content: const Text('A player with the same playerName or nickname already exists.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // No duplicate found, proceed with saving the changes
      saveChanges();
    }
  }

  void saveChanges() {
    if (validateRequiredFields()) {
      // Create or update the player
      if (isEditing) {
        widget.player!.playerName = _playerNameController.text;
        widget.player!.nickname = _nicknameController.text;
        widget.player!.email = _emailController.text;
        widget.player!.phoneNumber = _phoneNumberController.text;
        widget.player!.status = _statusController.text;
        widget.player!.ownerId = currentUser!.id;
        currentUser!.addPlayerFriend(widget.player!);
      }
      widget.onSaveChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        (widget.editingOrAdding == 'Edit') ? Text("Edit Player Attributes (${widget.player!.id})") : const Text("Add A New Player"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _playerNameController,
          decoration: const InputDecoration(labelText: 'Player Name'),
          enabled: widget.allowEditing,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nicknameController,
          decoration: const InputDecoration(labelText: 'Nickname'),
          enabled: widget.allowEditing,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          enabled: widget.allowEditing,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(labelText: 'Phone Number'),
          enabled: widget.allowEditing,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _statusController,
          decoration: const InputDecoration(labelText: 'Status'),
          enabled: widget.allowEditing,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            checkDuplicate();
          },
          child: (widget.editingOrAdding == 'Edit') ? const Text("Save Changes") : const Text("Add Player"),
        ),
      ],
    );
  }
}

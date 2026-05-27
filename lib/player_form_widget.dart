import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/contact_identity.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';

import 'player.dart';

class PlayerForm extends StatefulWidget {
  const PlayerForm(
      {super.key,
      this.player,
      required this.allowEditing,
      required this.onSaveChanges,
      required this.editingOrAdding});

  final bool allowEditing;
  final String editingOrAdding;
  final VoidCallback onSaveChanges;
  final Player? player;

  @override
  PlayerFormState createState() => PlayerFormState();
}

class PlayerFormState extends State<PlayerForm> {
  Player? get currentUser => UserProvider().loggedInUser;

  bool isDuplicate = false;

  late TextEditingController _emailController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _playerNameController;

  @override
  void dispose() {
    _playerNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    _playerNameController =
        TextEditingController(text: widget.player?.playerName ?? '');
    _nicknameController =
        TextEditingController(text: widget.player?.nickname ?? '');
    _emailController = TextEditingController(text: widget.player?.email ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.player?.phoneNumber ?? '');
  }

  bool get isEditing => widget.player != null;
  bool get isGuestScorekeeper =>
      currentUser == null && widget.player?.id == 'guest';

  Future<void> loadCurrentUser() async {}

  bool validateRequiredFields() {
    final playerNameMissing =
        !isGuestScorekeeper && _playerNameController.text.isEmpty;
    if (playerNameMissing || _nicknameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing required fields'),
            content: playerNameMissing
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
    final List<Player> allPlayers =
        currentUser?.getAllPlayerFriends() ?? Player.players;
    isDuplicate = allPlayers.any((player) =>
        player != widget.player &&
        (player.playerName == _playerNameController.text &&
            player.nickname == _nicknameController.text));

    if (isDuplicate) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Duplicate Player'),
            content: const Text(
                'A player with the same playerName or nickname already exists.'),
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

  Future<void> saveChanges() async {
    if (isGuestScorekeeper) {
      _playerNameController.text = _nicknameController.text;
    }
    if (validateRequiredFields()) {
      if (widget.player != null) {
        widget.player!.playerName = _playerNameController.text;
        widget.player!.nickname = _nicknameController.text;
        widget.player!.email =
            ContactIdentity.normalizeEmail(_emailController.text);
        widget.player!.phoneNumber =
            ContactIdentity.normalizePhoneNumber(_phoneNumberController.text);
        widget.player!.normalizedEmail = widget.player!.email;
        widget.player!.normalizedPhoneNumber = widget.player!.phoneNumber;
        widget.player!.ownerId = currentUser?.id ?? 'guest';

        if (widget.editingOrAdding == 'Add') {
          if (currentUser != null) {
            final canonicalPlayer =
                await currentUser!.addPlayerFriend(widget.player!);
            widget.player!.playerName = canonicalPlayer.playerName;
            widget.player!.nickname = canonicalPlayer.nickname;
            widget.player!.email = canonicalPlayer.email;
            widget.player!.phoneNumber = canonicalPlayer.phoneNumber;
          } else {
            final canonicalPlayer =
                await Player.resolveGuestPlayer(widget.player!);
            final existingIndex = Player.players
                .indexWhere((player) => player.id == canonicalPlayer.id);
            if (existingIndex == -1) {
              Player.players.add(canonicalPlayer);
            } else {
              Player.players[existingIndex] = canonicalPlayer;
            }
            await Player.saveLocalGuestPlayers();
          }
        } else if (currentUser != null) {
          await Player.updateUnclaimedPlayer(widget.player!);
        } else {
          await Player.saveLocalGuestPlayers();
        }
      }
      widget.onSaveChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        (widget.editingOrAdding == 'Edit')
            ? const Text("Edit Player Attributes")
            : const Text("Add A New Player"),
        const SizedBox(height: 10),
        if (isGuestScorekeeper) ...[
          TextFormField(
            controller: _nicknameController,
            decoration: const InputDecoration(labelText: 'Nickname'),
            enabled: widget.allowEditing,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(
                    promptMessage:
                        'Log in or sign up to set your real name, email, and phone number!',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.black87),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Log in or sign up to set your real name, email, and phone number!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
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
        ],
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            checkDuplicate();
          },
          child: (widget.editingOrAdding == 'Edit')
              ? const Text("Save Changes")
              : const Text("Add Player"),
        ),
      ],
    );
  }
}

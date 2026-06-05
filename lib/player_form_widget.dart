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
      required this.editingOrAdding,
      this.isQuickPlay = false});

  final bool allowEditing;
  final String editingOrAdding;
  final VoidCallback onSaveChanges;
  final Player? player;
  final bool isQuickPlay;

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
  late bool _shareName;
  late bool _shareEmail;
  late bool _sharePhone;


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
    _playerNameController =
        TextEditingController(text: widget.player?.playerName ?? '');
    _nicknameController =
        TextEditingController(text: widget.player?.nickname ?? '');
    _emailController = TextEditingController(text: widget.player?.email ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.player?.phoneNumber ?? '');
    _shareName = widget.player?.shareName ?? true;
    _shareEmail = widget.player?.shareEmail ?? true;
    _sharePhone = widget.player?.sharePhone ?? true;
  }

  bool get isEditing => widget.player != null;
  bool get isGuestScorekeeper =>
      currentUser == null && widget.player?.id == 'guest';

  bool validateRequiredFields() {
    final isImplicitQuickPlay = _emailController.text.trim().isEmpty &&
        _phoneNumberController.text.trim().isEmpty;
    final playerNameMissing =
        !isGuestScorekeeper && !isImplicitQuickPlay && _playerNameController.text.isEmpty;
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

  Future<void> checkDuplicate() async {
    // Check for duplicates before saving
    final List<Player> allPlayers =
        currentUser?.getAllPlayerFriends() ?? Player.players;
    isDuplicate = allPlayers.any((player) =>
        player != widget.player &&
        (player.playerName == _playerNameController.text &&
            player.nickname == _nicknameController.text));

    if (isDuplicate) {
      if (!mounted) return;
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
      return;
    }

    final normalizedEmail = ContactIdentity.normalizeEmail(_emailController.text);
    final normalizedPhone = ContactIdentity.normalizePhoneNumber(_phoneNumberController.text);

    if (normalizedEmail != null || normalizedPhone != null) {
      bool localCollision = allPlayers.any((player) {
        if (widget.player != null && player.id == widget.player!.id) {
          return false;
        }
        final playerNormEmail = player.normalizedEmail ?? ContactIdentity.normalizeEmail(player.email);
        final playerNormPhone = player.normalizedPhoneNumber ?? ContactIdentity.normalizePhoneNumber(player.phoneNumber);

        final emailMatch = normalizedEmail != null && playerNormEmail == normalizedEmail;
        final phoneMatch = normalizedPhone != null && playerNormPhone == normalizedPhone;
        return emailMatch || phoneMatch;
      });

      bool dbCollision = false;
      try {
        if (normalizedEmail != null) {
          final dbPlayer = await Player.getPlayerByEmailFromDB(normalizedEmail);
          if (dbPlayer != null && dbPlayer.id != widget.player?.id) {
            dbCollision = true;
          }
        }
        if (!dbCollision && normalizedPhone != null) {
          final dbPlayer = await Player.getPlayerByPhoneFromDB(normalizedPhone);
          if (dbPlayer != null && dbPlayer.id != widget.player?.id) {
            dbCollision = true;
          }
        }
      } catch (e) {
        debugPrint('Error checking database collision: $e');
      }

      if (localCollision || dbCollision) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Contact Collision'),
              content: const Text(
                  'This email/phone number is already in use by another player.'),
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
        return;
      }
    }

    // No duplicate or collision found, proceed with saving the changes
    saveChanges();
  }

  Future<void> saveChanges() async {
    if (isGuestScorekeeper) {
      _playerNameController.text = 'Guest';
    }
    final isImplicitQuickPlay = _emailController.text.trim().isEmpty &&
        _phoneNumberController.text.trim().isEmpty;
    if (isImplicitQuickPlay && _playerNameController.text.trim().isEmpty) {
      _playerNameController.text = _nicknameController.text.trim().isEmpty
          ? 'Guest'
          : _nicknameController.text.trim();
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
        widget.player!.shareName = _shareName;
        widget.player!.shareEmail = _shareEmail;
        widget.player!.sharePhone = _sharePhone;
        widget.player!.ownerId = currentUser?.id ?? 'guest';
        widget.player!.isQuickPlay = isImplicitQuickPlay;

        if (widget.editingOrAdding == 'Add') {
          if (currentUser != null) {
            final canonicalPlayer =
                await currentUser!.addPlayerFriend(widget.player!);
            widget.player!.playerName = canonicalPlayer.playerName;
            widget.player!.nickname = canonicalPlayer.nickname;
            widget.player!.email = canonicalPlayer.email;
            widget.player!.phoneNumber = canonicalPlayer.phoneNumber;
            widget.player!.isQuickPlay = canonicalPlayer.isQuickPlay;
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
    return SingleChildScrollView(
      child: Column(
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
            _buildTextField(
              controller: _playerNameController,
              labelText: 'Player Name',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nicknameController,
              labelText: 'Nickname',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _emailController,
              labelText: 'Email',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _phoneNumberController,
              labelText: 'Phone Number',
            ),
            const SizedBox(height: 10),
            if (UserProvider().loggedInUser?.id != null &&
                UserProvider().loggedInUser?.id == widget.player?.id)
              _buildPrivacySettings(),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      enabled: widget.allowEditing,
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Privacy Settings'),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show Real Name'),
          value: _shareName,
          onChanged: widget.allowEditing
              ? (value) {
                  setState(() {
                    _shareName = value ?? true;
                  });
                }
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show Email'),
          value: _shareEmail,
          onChanged: widget.allowEditing
              ? (value) {
                  setState(() {
                    _shareEmail = value ?? true;
                  });
                }
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show Phone Number'),
          value: _sharePhone,
          onChanged: widget.allowEditing
              ? (value) {
                  setState(() {
                    _sharePhone = value ?? true;
                  });
                }
              : null,
        ),
      ],
    );
  }
}

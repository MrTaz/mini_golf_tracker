import 'package:flutter/material.dart';

import 'player.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({super.key, required this.player});

  final Player player;

  @override
  PlayerDetailsScreenState createState() => PlayerDetailsScreenState();
}

class PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late Player _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  Widget _buildFormField(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return TextFormField(
      initialValue: value ?? '',
      decoration: InputDecoration(
        labelText: label,
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Player Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildFormField('Player Name', _player.playerName, (value) {
              setState(() {
                _player.playerName = value!;
              });
            }),
            _buildFormField('Nickname', _player.nickname, (value) {
              setState(() {
                _player.nickname = value!;
              });
            }),
            _buildFormField('Email', _player.email, (value) {
              setState(() {
                _player.email = value;
              });
            }),
            _buildFormField('Phone Number', _player.phoneNumber, (value) {
              setState(() {
                _player.phoneNumber = value;
              });
            }),
            _buildFormField('Status', _player.status, (value) {
              setState(() {
                _player.status = value;
              });
            }),
            _buildFormField('Total Score', _player.totalScore.toString(), (value) {
              setState(() {
                _player.totalScore = num.parse(value!);
              });
            }),
          ],
        ),
      ),
    );
  }
}

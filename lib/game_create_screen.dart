import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class GameCreateScreen extends StatefulWidget {
  const GameCreateScreen({Key? key}) : super(key: key);

  @override
  GameCreateScreenState createState() => GameCreateScreenState();
}

class GameCreateScreenState extends State<GameCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  Course? _selectedCourse;
  late List<Player> _selectedPlayers;
  late DateTime _scheduledTime;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = [];
    _scheduledTime = DateTime.now();
  }

  Future<void> _selectCourse() async {
    final Course? selectedCourse = await Navigator.push<Course?>(
      context,
      MaterialPageRoute(
          builder: (context) => const CoursesScreen(
                creatingGame: true,
              )),
    );
    if (selectedCourse != null) {
      setState(() {
        _selectedCourse = selectedCourse;
      });
    }
  }

  Future<void> _selectPlayers() async {
    final List<Player>? selectedPlayers = await Navigator.push<List<Player>?>(
      context,
      MaterialPageRoute(
          builder: (context) => const PlayersScreen(
                creatingGame: true,
              )),
    );
    if (selectedPlayers != null && selectedPlayers.isNotEmpty) {
      setState(() {
        _selectedPlayers = selectedPlayers;
      });
    }
  }

  Future<void> _createGame() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      if (_selectedCourse == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a course'),
        ));
        return;
      }
      if (_selectedPlayers.length < 2 || _selectedPlayers.length > 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select between 2 and 6 players'),
        ));
        return;
      }

      final Game newGame = Game(name: name, course: _selectedCourse!, players: [], scheduledTime: _scheduledTime);
      for (var player in _selectedPlayers) {
        PlayerGameInfo pgi = PlayerGameInfo(playerId: player.id, gameId: newGame.id, scores: []);
        newGame.addPlayer(pgi);
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String gameJson = jsonEncode(newGame);
      await prefs.setString(newGame.id, gameJson);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Game created successfully'),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Create Game'),
      ),
      body: Stack(children: [
        Utilities.backdropImageContinerWidget(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Game Name'),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a game name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text('Course'),
                  subtitle: Text(_selectedCourse?.name ?? 'Select a course'),
                  onTap: _selectCourse,
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text('Players'),
                  subtitle: Text(
                    '${_selectedPlayers.length} ${_selectedPlayers.length == 1 ? 'player' : 'players'} selected',
                  ),
                  onTap: _selectPlayers,
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(DateFormat.yMMMMd().add_jm().format(_scheduledTime)),
                  onTap: () async {
                    final DateTime? selectedTime = await showDatePicker(
                      context: context,
                      initialDate: _scheduledTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (selectedTime != null) {
                      final TimeOfDay? selectedTimeOfDay = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
                      );

                      if (selectedTimeOfDay != null) {
                        final DateTime selectedDateTime = DateTime(
                          selectedTime.year,
                          selectedTime.month,
                          selectedTime.day,
                          selectedTimeOfDay.hour,
                          selectedTimeOfDay.minute,
                        );

                        setState(() {
                          _scheduledTime = selectedDateTime;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _createGame,
                  child: const Text('Create Game'),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class GameCreateScreen extends StatefulWidget {
  const GameCreateScreen({super.key});

  @override
  GameCreateScreenState createState() => GameCreateScreenState();
}

class GameCreateScreenState extends State<GameCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  late DateTime _scheduledTime;
  Course? _selectedCourse;
  late List<Player> _selectedPlayers;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = [];
    _scheduledTime = DateTime.now();
  }

  // ─── Test-only accessors ──────────────────────────────────────────────────
  @visibleForTesting
  void setSelectedCourseForTesting(Course? c) {
    setState(() => _selectedCourse = c);
  }

  @visibleForTesting
  void setSelectedPlayersForTesting(List<Player> players) {
    setState(() => _selectedPlayers = players);
  }

  @visibleForTesting
  void setScheduledTimeForTesting(DateTime dt) {
    setState(() => _scheduledTime = dt);
  }

  @visibleForTesting
  void handleCourseSelectionResult(Course? course) {
    if (course != null) {
      setState(() => _selectedCourse = course);
    }
  }

  @visibleForTesting
  void handlePlayersSelectionResult(List<Player>? players) {
    if (players != null && players.isNotEmpty) {
      setState(() => _selectedPlayers = players);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

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

  void _showGatedSchedulingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Scheduling is Gated'),
            ],
          ),
          content: const Text(
            'To schedule games in advance, please log in or sign up for an account. Logged-in users can schedule games and sync them across devices!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Log In / Sign Up'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGame() async {
    if (UserProvider().loggedInUser == null) {
      _scheduledTime = DateTime.now();
    }
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

      final Game newGame = Game(
          name: name,
          course: _selectedCourse!,
          players: [],
          scheduledTime: _scheduledTime);
      for (var player in _selectedPlayers) {
        PlayerGameInfo pgi =
            PlayerGameInfo(playerId: player.id, gameId: newGame.id, scores: []);
        newGame.addPlayer(pgi);
      }

      newGame.status = "started";
      newGame.startTime = DateTime.now();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String gameJson = jsonEncode(newGame);
      await prefs.setString(newGame.id, gameJson);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Game created successfully'),
      ));
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameInprogressScreen(currentGame: newGame),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = UserProvider().loggedInUser == null;
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
                  title: Text(
                    'Start Time',
                    style: TextStyle(
                      color: isGuest ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMMd().add_jm().format(_scheduledTime),
                    style: TextStyle(
                      color: isGuest ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    isGuest ? Icons.lock : Icons.edit,
                    color: isGuest ? Colors.grey : null,
                  ),
                  onTap: isGuest
                      ? _showGatedSchedulingDialog
                      : () async {
                          final DateTime? selectedTime = await showDatePicker(
                            context: context,
                            initialDate: _scheduledTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );

                          if (selectedTime != null) {
                            if (!context.mounted) return;
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

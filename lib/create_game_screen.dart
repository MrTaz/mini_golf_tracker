import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'courses_screen.dart';
import 'game.dart';
import 'course.dart';
import 'player_game_info.dart';
import 'players_list_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({Key? key}) : super(key: key);

  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  Course? _selectedCourse;
  late List<PlayerGameInfo> _selectedPlayers;
  late DateTime _startTime;
  late bool _gameStarted;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = [];
    _startTime = DateTime.now();
    _gameStarted = false;
  }

  Future<void> _selectCourse() async {
    final Course? selectedCourse = await Navigator.push<Course?>(
      context,
      MaterialPageRoute(builder: (context) => CoursesScreen()),
    );
    if (selectedCourse != null) {
      setState(() {
        _selectedCourse = selectedCourse;
      });
    }
  }

  Future<void> _selectPlayers() async {
    final List<PlayerGameInfo>? selectedPlayers = await Navigator.push<List<PlayerGameInfo>?>(
      context,
      MaterialPageRoute(builder: (context) => PlayersScreen()),
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

      final Game newGame = Game(
        name: name,
        course: _selectedCourse!,
        players: _selectedPlayers,
        startTime: _startTime,
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String gameJson = newGame.toJson().toString();
      await prefs.setString('unstarted_game', gameJson);

      setState(() {
        _gameStarted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Game created successfully'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Game'),
      ),
      body: Padding(
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
                subtitle: Text(DateFormat.yMMMMd().add_jm().format(_startTime)),
                onTap: () async {
                  final DateTime? selectedTime = await showDatePicker(
                    context: context,
                    initialDate: _startTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (selectedTime != null) {
                    final TimeOfDay? selectedTimeOfDay = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startTime),
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
                        _startTime = selectedDateTime;
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
    );
  }
}

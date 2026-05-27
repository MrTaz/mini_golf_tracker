import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      if (course.id.isEmpty) {
        setState(() => _selectedCourse = null);
      } else {
        setState(() => _selectedCourse = course);
      }
    }
  }

  @visibleForTesting
  void handlePlayersSelectionResult(List<Player>? players) {
    if (players != null && players.isNotEmpty) {
      setState(() => _selectedPlayers = players);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _selectCourse() async {
    _dismissKeyboard();
    HapticFeedback.selectionClick();
    final Course? selectedCourse = await Navigator.push<Course?>(
      context,
      MaterialPageRoute(
          builder: (context) => CoursesScreen(
                creatingGame: true,
                selectedCourse: _selectedCourse,
              )),
    );
    if (selectedCourse != null) {
      if (selectedCourse.id.isEmpty) {
        setState(() {
          _selectedCourse = null;
        });
      } else {
        setState(() {
          _selectedCourse = selectedCourse;
        });
      }
    }
  }

  Future<void> _selectPlayers() async {
    _dismissKeyboard();
    HapticFeedback.selectionClick();
    final List<Player>? selectedPlayers = await Navigator.push<List<Player>?>(
      context,
      MaterialPageRoute(
          builder: (context) => PlayersScreen(
                creatingGame: true,
                currentlySelectedPlayers: _selectedPlayers,
              )),
    );
    if (selectedPlayers != null) {
      setState(() {
        _selectedPlayers = selectedPlayers;
      });
    }
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasSelection,
  }) {
    final Color activeColor = Colors.green.shade700;
    final Color borderColor = hasSelection ? activeColor : Colors.grey.shade300;
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: hasSelection ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: borderColor,
              width: hasSelection ? 2.5 : 1.5,
            ),
            boxShadow: hasSelection
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 26.0,
                color: hasSelection ? activeColor : Colors.grey.shade500,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: hasSelection
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: hasSelection
                            ? Colors.green.shade900
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    _dismissKeyboard();
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
    final String playerSelectionText =
        '${_selectedPlayers.length} ${_selectedPlayers.length == 1 ? 'player' : 'players'} selected';
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      resizeToAvoidBottomInset: false,
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
              padding: const EdgeInsets.only(bottom: 184.0),
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
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );

                          if (selectedTime != null) {
                            if (!context.mounted) return;
                            final TimeOfDay? selectedTimeOfDay =
                                await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(_scheduledTime),
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
              ],
            ),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionCard(
                        title: 'Course',
                        subtitle: _selectedCourse?.name ?? 'Select a course',
                        icon: Icons.flag_rounded,
                        onTap: _selectCourse,
                        hasSelection: _selectedCourse != null,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _buildSelectionCard(
                        title: 'Players',
                        subtitle: playerSelectionText,
                        icon: Icons.groups_rounded,
                        onTap: _selectPlayers,
                        hasSelection: _selectedPlayers.isNotEmpty,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createGame,
                    child: const Text('Create Game'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course.dart';
import 'game.dart';
import 'players_list_screen.dart';
import 'players_screen.dart';

class GameStartScreen extends StatefulWidget {
  final Game? unstartedGame;
  final Function()? callback;
  const GameStartScreen({super.key, this.unstartedGame, this.callback});

  @override
  GameStartScreenState createState() => GameStartScreenState();
}

class GameStartScreenState extends State<GameStartScreen> {
  late List<PlayerGameInfo> _playersInfo;
  late Course? _newGameCourse = null;
  late TextEditingController _nameController;
  bool _isCreatingGame = false;

  @override
  void initState() {
    super.initState();
    // debugPrint("unstartedGame: ${widget.unstartedGame?.toJson()}");
    _initializePlayersInfo();

    if (widget.unstartedGame == null) {
      _isCreatingGame = true;
      _nameController = TextEditingController();
      _showGameCreationDialog();
    }
  }

  Future<void> _showGameCreationDialog() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Create New Game'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter a name for the new game:'),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Game Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    final newGame = Game(
                        name: _nameController.text,
                        players: [],
                        course: Course(
                            id: DateTime.now().millisecondsSinceEpoch,
                            name: "Please select course",
                            numberOfHoles: 0,
                            parStrokes: {}),
                        scheduledTime: DateTime.now());
                    Navigator.pop(context, true);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GameStartScreen(
                                unstartedGame: newGame,
                                callback: () => {(widget.callback != null) ? widget.callback!() : null},
                              )),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    });
  }

  void _initializePlayersInfo() {
    if (widget.unstartedGame != null) {
      _playersInfo = (widget.unstartedGame?.players ?? [])
          .map((player) => PlayerGameInfo(playerId: player.playerId, courseId: player.courseId, scores: player.scores))
          .toList();
    } else {
      _playersInfo = [];
    }
  }

  void _selectCourse() async {
    final Course? selectedCourse = await Navigator.push<Course?>(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CoursesScreen(selectedCourse: (_isCreatingGame) ? _newGameCourse : widget.unstartedGame?.course)),
    );

    if (selectedCourse != null) {
      setState(() {
        // debugPrint("Setting course to ${selectedCourse.toJson()}");
        if (_isCreatingGame) {
          _newGameCourse = selectedCourse;
        } else {
          widget.unstartedGame!.course = selectedCourse;
        }
      });
    }
  }

  void _editStartTime(context) async {
    final DateTime? selectedTime = await showDatePicker(
      context: context,
      initialDate: widget.unstartedGame!.scheduledTime,
      firstDate: (DateTime.now().isAfter(widget.unstartedGame!.scheduledTime))
          ? widget.unstartedGame!.scheduledTime
          : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedTime != null) {
      final TimeOfDay? selectedTimeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.unstartedGame!.scheduledTime),
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
          widget.unstartedGame!.scheduledTime = selectedDateTime;
        });
      }
    }
  }

  void _addPlayer() async {
    final List<Player>? selectedPlayers = await Navigator.push<List<Player>?>(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PlayersScreen(creatingGame: true, currentlySelectedPlayers: widget.unstartedGame!.players)),
    );
    if (selectedPlayers != null && selectedPlayers.isNotEmpty) {
      setState(() {
        _playersInfo.clear();
        for (Player _selectedPlayer in selectedPlayers) {
          _playersInfo
              .add(PlayerGameInfo(playerId: _selectedPlayer.id, courseId: widget.unstartedGame!.course.id, scores: []));
        }
        widget.unstartedGame!.players.replaceRange(0, widget.unstartedGame!.players.length, _playersInfo);
      });
    }
  }

  void _removePlayer(int index) {
    setState(() {
      _playersInfo.removeAt(index);
      widget.unstartedGame!.players.removeAt(index);
    });
  }

  Future<void> _updateUnstartedGame() async {
    if (widget.unstartedGame == null) {
      return;
    }

    if (widget.unstartedGame?.course.numberOfHoles == 0) {
      return;
    }

    if (widget.unstartedGame!.players.length < 2 || widget.unstartedGame!.players.length > 6) {
      return;
    }

    widget.unstartedGame!.players.replaceRange(0, widget.unstartedGame!.players.length, _playersInfo);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String unstartedGameJson = jsonEncode(widget.unstartedGame!);
    await prefs.setString(widget.unstartedGame!.id, unstartedGameJson);
    if (widget.callback != null) {
      widget.callback!();
    }
  }

  void _scheduleGame(context) async {
    if (widget.unstartedGame == null) {
      return;
    }

    if (widget.unstartedGame?.course.numberOfHoles == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a valid course'),
      ));
      return;
    }

    if (widget.unstartedGame!.players.length < 2 || widget.unstartedGame!.players.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select between 2 and 6 players'),
      ));
      return;
    }

    if (widget.unstartedGame!.scheduledTime != DateTime(0)) {
      widget.unstartedGame!.scheduledTime = DateTime.now();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Scheduling your game to start ${Utilities.formatStartTime(widget.unstartedGame!.scheduledTime)}.'),
    ));
    await _updateUnstartedGame();
    Navigator.pop(context);
  }

  void _startGame(context) async {
    if (widget.unstartedGame == null) {
      return;
    }

    if (widget.unstartedGame?.course.numberOfHoles == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a valid course'),
      ));
      return;
    }

    if (widget.unstartedGame!.players.length < 2 || widget.unstartedGame!.players.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select between 2 and 6 players'),
      ));
      return;
    }

    if (widget.unstartedGame!.scheduledTime != DateTime(0)) {
      widget.unstartedGame!.scheduledTime = DateTime.now();
    }

    Duration scheduledTimeDiff = widget.unstartedGame!.scheduledTime.difference(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute));

    if (scheduledTimeDiff > const Duration(minutes: 60)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Your scheduled start time is over an hour away (${scheduledTimeDiff.inHours} mins), starting now anyways.'),
      ));
    }

    widget.unstartedGame!.status = "started";
    widget.unstartedGame!.startTime = DateTime.now();

    await _updateUnstartedGame();

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) {
        return GameInprogressScreen(currentGame: widget.unstartedGame!);
      }),
    );
  }

  // UI for player list items
  Widget _buildPlayerListItem(Player player, int playerIndex) {
    bool isSelected = false;

    return InkWell(
      key: Key("inkwellOrderTap${player.id}"),
      onTap: () {
        setState(() {
          isSelected = !isSelected;
        });
      },
      child: PlayerListItem(
        key: Key(player.id.toString()),
        player: player,
        creatingGame: false,
        onPlayerSelected: null,
        isSelected: isSelected,
        listOrderNumber: playerIndex + 1,
        onRemove: () => _removePlayer(playerIndex),
      ),
    );
  }

  // UI for the course card
  Widget _buildSelectCourseCard() {
    Course? course = (_isCreatingGame) ? _newGameCourse : widget.unstartedGame?.course;
    // debugPrint("setting course: ${course?.toJson()}");

    return Center(
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Course selected',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ListTile(
                title: Text(course?.name ?? 'Select Course'),
                subtitle: Text("${course?.numberOfHoles.toString() ?? 'No course selected'}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _selectCourse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI for the player order section
  Widget _buildPlayerOrderSection() {
    return Center(
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set player\'s play order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (Utilities.isMobile)
                const Text(
                  'Press and hold a player to drag and reorder.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      children: _playersInfo.asMap().entries.map((entry) {
                        final playerInfo = entry.value;
                        final playerIndex = entry.key;
                        final player = Player.getPlayerById(playerInfo.playerId);
                        return _buildPlayerListItem(player!, playerIndex);
                      }).toList(),
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final PlayerGameInfo player = _playersInfo.removeAt(oldIndex);
                          _playersInfo.insert(newIndex, player);
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_playersInfo.length < 6)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _addPlayer,
                      child: const Text('Add players'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // UI for the scheduled start time section
  Widget _buildScheduledStartTimeSection() {
    return Center(
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Schedule start time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ListTile(
                title: Text(Utilities.formatStartTime(widget.unstartedGame!.scheduledTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () {
                    _editStartTime(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isCreatingGame) {
      _nameController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isCreatingGame) {
          [await _updateUnstartedGame()];
        }
        return true; // Return true to allow the back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text('Start Game - ${widget.unstartedGame?.name ?? 'New Game'}'),
        ),
        body: Stack(children: [
          Utilities.backdropImageContinerWidget(),
          if (!_isCreatingGame) ...[
            SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height + 200,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildSelectCourseCard(),
                      _buildPlayerOrderSection(),
                      _buildScheduledStartTimeSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ]),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingActionButton.extended(
                heroTag: "btnScheduleGame",
                onPressed: () {
                  _scheduleGame(context);
                },
                label: const Row(
                  children: [Icon(Icons.schedule), Text("Schedule game")],
                ),
              ),
              FloatingActionButton.extended(
                heroTag: "btnStartGame",
                onPressed: () {
                  _startGame(context);
                },
                label: const Row(
                  children: [Icon(Icons.sports_golf_rounded), Text("Start the game!")],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//         // bottomSheet: Container(
//         //   padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//         //   color: Colors.grey[300],
//         //   child: Row(
//         //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         //     children: [
//         //       const Text(
//         //         'Press and hold a player to drag and reorder.',
//         //         style: TextStyle(fontStyle: FontStyle.italic),
//         //       ),
//         //       DropdownButton<int>(
//         //         value: 1, // Add your logic to set the selected value of the dropdown
//         //         items: _playersInfo.asMap().entries.map((entry) {
//         //           final playerIndex = entry.key;
//         //           return DropdownMenuItem<int>(
//         //             value: playerIndex + 1,
//         //             child: Text('${playerIndex + 1}${getPlayerPositionSuffix(playerIndex + 1)}'),
//         //           );
//         //         }).toList(),
//         //         onChanged: (newValue) {
//         //           // Add your logic to handle when the dropdown value is changed
//         //         },
//         //       ),
//         //     ],
//         //   ),
//         // ),

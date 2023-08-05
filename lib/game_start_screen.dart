import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  final Game unstartedGame;
  const GameStartScreen({super.key, required this.unstartedGame});

  @override
  _GameStartScreenState createState() => _GameStartScreenState();
}

class _GameStartScreenState extends State<GameStartScreen> {
  late List<PlayerGameInfo> _playersInfo;
  final isMobile =
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _initializePlayersInfo();
  }

  void _initializePlayersInfo() {
    _playersInfo = widget.unstartedGame.players
        .map((player) => PlayerGameInfo(playerId: player.playerId, courseId: player.courseId, scores: player.scores))
        .toList();
  }

  void _editCourse() async {
    final Course? selectedCourse = await Navigator.push<Course?>(
      context,
      MaterialPageRoute(builder: (context) => CoursesScreen(selectedCourse: widget.unstartedGame.course)),
    );

    if (selectedCourse != null) {
      setState(() {
        widget.unstartedGame.course = selectedCourse;
      });
    }
  }

  void _editStartTime() async {
    final DateTime? selectedTime = await showDatePicker(
      context: context,
      initialDate: widget.unstartedGame.scheduledTime,
      firstDate: (DateTime.now().isAfter(widget.unstartedGame.scheduledTime))
          ? widget.unstartedGame.scheduledTime
          : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedTime != null) {
      final TimeOfDay? selectedTimeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.unstartedGame.scheduledTime),
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
          widget.unstartedGame.scheduledTime = selectedDateTime;
        });
      }
    }
  }

  void _addPlayer() async {
    final List<Player>? selectedPlayers = await Navigator.push<List<Player>?>(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PlayersScreen(creatingGame: true, currentlySelectedPlayers: widget.unstartedGame.players)),
    );
    if (selectedPlayers != null && selectedPlayers.isNotEmpty) {
      setState(() {
        _playersInfo.clear();
        for (Player _selectedPlayer in selectedPlayers) {
          _playersInfo
              .add(PlayerGameInfo(playerId: _selectedPlayer.id, courseId: widget.unstartedGame.course.id, scores: []));
        }
        widget.unstartedGame.players.replaceRange(0, widget.unstartedGame.players.length, _playersInfo);
      });
    }
  }

  void _removePlayer(int index) {
    setState(() {
      _playersInfo.removeAt(index);
      widget.unstartedGame.players.removeAt(index);
    });
  }

  void _updateUnstartedGame() async {
    // Update the unstartedGame based on the changes in _playersInfo
    widget.unstartedGame.players.replaceRange(0, widget.unstartedGame.players.length, _playersInfo);
    // Save the updated unstartedGame to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String unstartedGameJson = jsonEncode(widget.unstartedGame);
    await prefs.setString(widget.unstartedGame.id, unstartedGameJson);
  }

  void _startGame(context) async {
    debugPrint("Checking if we can start game...");
    // if (widget.unstartedGame.course == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //     content: Text('Please select a course'),
    //   ));
    //   return;
    // }
    if (widget.unstartedGame.players.length < 2 || widget.unstartedGame.players.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select between 2 and 6 players'),
      ));
      return;
    }
    Duration scheduledTimeDiff = widget.unstartedGame.scheduledTime.difference(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute));
    if (scheduledTimeDiff > const Duration(minutes: 60)) {
      debugPrint(
          "Scheduled time ${widget.unstartedGame.scheduledTime} is greater than 1 hour difference ($scheduledTimeDiff) from now");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Your scheduled start time is over an hour away (${scheduledTimeDiff.inHours}), starting now anyways.'),
      ));
    }
    debugPrint("Starting game...");
    widget.unstartedGame.status = "started";
    widget.unstartedGame.startTime = DateTime.now();
    // Save the updated unstartedGame to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String unstartedGameJson = jsonEncode(widget.unstartedGame);
    await prefs.setString(widget.unstartedGame.id, unstartedGameJson);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) {
        return GameInprogressScreen(currentGame: widget.unstartedGame);
      }),
    );
  }

  _handlePlayerSelection(Player player) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _updateUnstartedGame(); // Save the updated unstartedGame
        return true; // Return true to allow the back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text('Start Game - ${widget.unstartedGame.name}'),
        ),
        body: Stack(children: [
          Utilities.backdropImageContinerWidget(),
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height + 200,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Center(
                          child: Card(
                              elevation: 6,
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(children: <Widget>[
                                    const Row(children: [
                                      Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Course selected',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ))
                                    ]),
                                    ListTile(
                                      title: Text(widget.unstartedGame.course.name),
                                      subtitle: Text("${widget.unstartedGame.course.numberOfHoles.toString()} holes"),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: _editCourse,
                                      ),
                                    )
                                  ])))),
                      Center(
                        child: Card(
                            elevation: 6,
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Set player\'s play order',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              if (isMobile) ...[
                                                const Text('Press and hold a player to drag and reorder.',
                                                    style: TextStyle(fontStyle: FontStyle.italic))
                                              ]
                                            ]),
                                      ),
                                      SingleChildScrollView(
                                          child: Column(children: [
                                        ReorderableListView(
                                          shrinkWrap: true,
                                          children: _playersInfo.asMap().entries.map((entry) {
                                            final playerInfo = entry.value;
                                            final playerIndex = entry.key;
                                            final player = Player.getPlayerById(playerInfo.playerId);
                                            bool isSelected = false;

                                            return InkWell(
                                                key: Key("inkwellOrderTap${player!.id}"),
                                                onTap: () {
                                                  setState(() {
                                                    isSelected = !isSelected;
                                                  });
                                                },
                                                child: PlayerListItem(
                                                    key: Key(player.id.toString()),
                                                    player: player,
                                                    creatingGame: false,
                                                    onPlayerSelected: _handlePlayerSelection,
                                                    isSelected: isSelected,
                                                    listOrderNumber: playerIndex + 1,
                                                    onRemove: () => _removePlayer(playerIndex)));
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
                                      ])),
                                      if (_playersInfo.length < 6) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: _addPlayer,
                                              child: const Text('Add players'),
                                            ),
                                          ],
                                        )
                                      ]
                                    ]))),
                      ),
                      Center(
                          child: Card(
                              elevation: 6,
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(children: <Widget>[
                                    const Row(children: [
                                      Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Scheduled start time',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ))
                                    ]),
                                    ListTile(
                                      title: Text(Utilities.formatStartTime(widget.unstartedGame.scheduledTime)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: _editStartTime,
                                      ),
                                    )
                                  ]))))
                    ],
                  )),
            ),
          )
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _startGame(context);
          },
          label: const Row(
            children: [Icon(Icons.sports_golf_rounded), Text("Start the game!")],
          ),
        ),
        // bottomSheet: Container(
        //   padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        //   color: Colors.grey[300],
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       const Text(
        //         'Press and hold a player to drag and reorder.',
        //         style: TextStyle(fontStyle: FontStyle.italic),
        //       ),
        //       DropdownButton<int>(
        //         value: 1, // Add your logic to set the selected value of the dropdown
        //         items: _playersInfo.asMap().entries.map((entry) {
        //           final playerIndex = entry.key;
        //           return DropdownMenuItem<int>(
        //             value: playerIndex + 1,
        //             child: Text('${playerIndex + 1}${getPlayerPositionSuffix(playerIndex + 1)}'),
        //           );
        //         }).toList(),
        //         onChanged: (newValue) {
        //           // Add your logic to handle when the dropdown value is changed
        //         },
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}

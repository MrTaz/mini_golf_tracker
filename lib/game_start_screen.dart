import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/players_list_screen.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameStartScreen extends StatefulWidget {
  const GameStartScreen({super.key, this.unstartedGame, this.callback});

  final Function()? callback;
  final Game? unstartedGame;

  @override
  GameStartScreenState createState() => GameStartScreenState();
}

class GameStartScreenState extends State<GameStartScreen> {
  final Player? loggedInUser = UserProvider().loggedInUser;

  bool _isCreatingGame = false;
  late TextEditingController _nameController;
  Course? _newGameCourse;
  late List<PlayerGameInfo> _playersInfo;

  @override
  void dispose() {
    if (_isCreatingGame) {
      _nameController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Utilities.debugPrintWithCallerInfo(
        "unstartedGame: ${widget.unstartedGame?.toJson()}");
    _initializePlayersInfo();

    if (UserProvider().loggedInUser == null && widget.unstartedGame != null) {
      widget.unstartedGame!.scheduledTime = DateTime.now();
    }

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
                            id: "",
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
                                callback: () => {
                                  (widget.callback != null)
                                      ? widget.callback!()
                                      : null
                                },
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
          .map((player) => PlayerGameInfo(
              playerId: player.playerId,
              gameId: widget.unstartedGame!.id,
              playOrderPosition:
                  player.playOrderPosition ?? 0, // Default value is 0 for null
              scores: player.scores,
              totalScore: player.totalScore,
              place: player.place))
          .toList();
      _playersInfo.sort(
          (a, b) => a.playOrderPosition!.compareTo(b.playOrderPosition as num));
    } else {
      _playersInfo = [];
    }
  }

  @visibleForTesting
  void selectCourseForTesting() => _selectCourse();

  @visibleForTesting
  void editStartTimeForTesting() => _editStartTime();

  @visibleForTesting
  Course? get newGameCourseForTesting => _newGameCourse;

  void _selectCourse() async {
    Utilities.debugPrintWithCallerInfo(
        "Opening select course screen, $_isCreatingGame, $_newGameCourse, ${widget.unstartedGame?.course.toJson()}");
    final Course? selectedCourse = await Navigator.push<Course?>(
      context,
      MaterialPageRoute(
          builder: (context) => CoursesScreen(
                selectedCourse: (_isCreatingGame)
                    ? _newGameCourse
                    : widget.unstartedGame?.course,
                creatingGame: true,
              )),
    );

    if (!mounted) return;
    if (selectedCourse != null) {
      setState(() {
        Utilities.debugPrintWithCallerInfo(
            "Setting course to ${selectedCourse.toJson()}");
        if (_isCreatingGame) {
          _newGameCourse = selectedCourse;
        } else {
          widget.unstartedGame!.course = selectedCourse;
        }
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

  void _editStartTime() async {
    if (UserProvider().loggedInUser == null) {
      _showGatedSchedulingDialog();
      return;
    }
    final DateTime? selectedTime = await showDatePicker(
      context: context,
      initialDate: widget.unstartedGame!.scheduledTime,
      firstDate: (DateTime.now().isAfter(widget.unstartedGame!.scheduledTime))
          ? widget.unstartedGame!.scheduledTime
          : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted) return;
    if (selectedTime != null) {
      final TimeOfDay? selectedTimeOfDay = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(widget.unstartedGame!.scheduledTime),
      );

      if (selectedTimeOfDay != null) {
        final DateTime selectedDateTime = DateTime(
          selectedTime.year,
          selectedTime.month,
          selectedTime.day,
          selectedTimeOfDay.hour,
          selectedTimeOfDay.minute,
        );

        if (!mounted) return;
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
          builder: (context) => PlayersScreen(
              creatingGame: true,
              currentlySelectedPlayers: widget.unstartedGame!.players)),
    );

    if (!mounted) return;
    if (selectedPlayers != null && selectedPlayers.isNotEmpty) {
      setState(() {
        _playersInfo.clear();
        for (Player selectedPlayer in selectedPlayers) {
          _playersInfo.add(PlayerGameInfo(
              playerId: selectedPlayer.id,
              gameId: widget.unstartedGame!.id,
              scores: []));
        }
        widget.unstartedGame!.players.replaceRange(
            0, widget.unstartedGame!.players.length, _playersInfo);
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

    if (widget.unstartedGame!.players.length < 2 ||
        widget.unstartedGame!.players.length > 6) {
      return;
    }

    widget.unstartedGame!.players
        .replaceRange(0, widget.unstartedGame!.players.length, _playersInfo);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String unstartedGameJson = jsonEncode(widget.unstartedGame!);
    await prefs.setString(widget.unstartedGame!.id, unstartedGameJson);
    if (loggedInUser != null) {
      await Game.saveGameToDatabase(widget.unstartedGame!, loggedInUser!);
    }
    if (widget.callback != null) {
      widget.callback!();
    }
  }

  void _scheduleGame() async {
    if (UserProvider().loggedInUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    if (widget.unstartedGame == null) {
      return;
    }

    if (widget.unstartedGame?.course.numberOfHoles == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a valid course'),
      ));
      return;
    }

    if (widget.unstartedGame!.players.length < 2 ||
        widget.unstartedGame!.players.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select between 2 and 6 players'),
      ));
      return;
    }

    if (UserProvider().loggedInUser != null) {
      final unstartedGames = await Game.fetchGamesForCurrentUser(
          UserProvider().loggedInUser!.id);
      bool hasConflict = false;
      for (final g in unstartedGames) {
        if (g.id != widget.unstartedGame!.id &&
            g.status == 'unstarted_game' &&
            g.scheduledTime.difference(widget.unstartedGame!.scheduledTime).abs() <=
                const Duration(hours: 2)) {
          hasConflict = true;
          break;
        }
      }
      if (hasConflict) {
        if (!mounted) return;
        final bool? doubleBook = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Scheduling Conflict'),
              content: const Text(
                  'You already have a game scheduled near this time. Do you want to double-book?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Double-Book'),
                ),
              ],
            );
          },
        );
        if (doubleBook != true) return;
      }
    }

    if (widget.unstartedGame?.scheduledTime == null ||
        widget.unstartedGame!.scheduledTime == DateTime(0)) {
      Utilities.debugPrintWithCallerInfo(
          "** Unstarted game did not have a scheduled Time: ${widget.unstartedGame!.scheduledTime}");
      widget.unstartedGame!.scheduledTime = DateTime.now();
    }

    final String formattedTime =
        await Utilities.formatStartTime(widget.unstartedGame!.scheduledTime);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Scheduling your game to start $formattedTime.'),
    ));
    await _updateUnstartedGame();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _startGame() async {
    if (widget.unstartedGame == null) {
      return;
    }

    if (widget.unstartedGame?.course.numberOfHoles == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a valid course'),
      ));
      return;
    }

    if (widget.unstartedGame!.players.length < 2 ||
        widget.unstartedGame!.players.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select between 2 and 6 players'),
      ));
      return;
    }

    final activeGames =
        await Game.getLocallySavedGames(gameStatusTypes: ['started']);
    if (activeGames.isNotEmpty) {
      if (!mounted) return;
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Warning'),
            content: const Text(
                'You already have a game in progress. Starting a new game will put your current game on hold.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }

    final creator = UserProvider().loggedInUser;
    if (creator != null) {
      final isCreatorInGame =
          widget.unstartedGame!.players.any((p) => p.playerId == creator.id);
      if (!isCreatorInGame) {
        if (!mounted) return;
        final startAnyway = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("You are not playing!"),
              content: const Text(
                  "You have not added yourself to the player list for this game. Do you want to start the game anyway?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  key: const Key("btnStartAnyway"),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Start Anyway"),
                ),
              ],
            );
          },
        );
        if (!mounted) return;
        if (startAnyway != true) {
          return;
        }
      }
    }

    if (widget.unstartedGame!.scheduledTime == DateTime(0)) {
      widget.unstartedGame!.scheduledTime = DateTime.now();
    }

    Duration scheduledTimeDiff = widget.unstartedGame!.scheduledTime.difference(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
            DateTime.now().hour, DateTime.now().minute));

    if (scheduledTimeDiff > const Duration(minutes: 60)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Your scheduled start time is over an hour away (${scheduledTimeDiff.inHours} mins), starting now anyways.'),
      ));
    }

    widget.unstartedGame!.status = "started";
    widget.unstartedGame!.startTime = DateTime.now();

    await _updateUnstartedGame();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) {
        return GameInprogressScreen(currentGame: widget.unstartedGame!);
      }),
    );
  }

  // UI for player list items
  Widget _buildPlayerListItem(Player player, int playerIndex, String uniqueId) {
    bool isSelected = false;

    return InkWell(
      key: Key("inkwellOrderTap$uniqueId"),
      onTap: () {
        setState(() {
          isSelected = !isSelected;
        });
      },
      child: PlayerListItem(
        key: Key(uniqueId),
        player: player,
        creatingGame: false,
        onPlayerSelected: null,
        isSelected: isSelected,
        listOrderNumber: playerIndex + 1,
        onRemove: () => _removePlayer(playerIndex),
        showDragHandle: true,
      ),
    );
  }

  // UI for the course card
  Widget _buildSelectCourseCard() {
    Utilities.debugPrintWithCallerInfo("Creating new game? $_isCreatingGame");
    Course? course =
        (_isCreatingGame) ? _newGameCourse : widget.unstartedGame?.course;
    Utilities.debugPrintWithCallerInfo("setting course: ${course?.toJson()}");

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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ListTile(
                title: Text(course?.name ?? 'Select Course'),
                subtitle: Text(course != null
                    ? '${course.numberOfHoles} holes - Total Par: ${course.parStrokes.values.fold<int>(0, (a, b) => a + b)}'
                    : 'No course selected'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _selectCourse,
                    child: const Text('Change course'),
                  ),
                ],
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
                        final gamePlayerInfo = widget.unstartedGame!.players
                            .firstWhere((player) =>
                                player.playerId == playerInfo.playerId);
                        Player? player;
                        for (final availablePlayer in Player.players) {
                          if (availablePlayer.id == gamePlayerInfo.playerId) {
                            player = availablePlayer;
                            break;
                          }
                        }
                        player ??= UserProvider()
                            .loggedInUser
                            ?.getPlayerFriendById(gamePlayerInfo.playerId);
                        if (player?.id == '' &&
                            UserProvider().loggedInUser?.id ==
                                gamePlayerInfo.playerId) {
                          player = UserProvider().loggedInUser;
                        }
                        player ??= Player(
                          id: gamePlayerInfo.playerId,
                          playerName: gamePlayerInfo.playerId,
                          nickname: gamePlayerInfo.playerId,
                          ownerId: UserProvider().loggedInUser?.id ?? 'guest',
                          totalScore: gamePlayerInfo.totalScore,
                        );
                        return _buildPlayerListItem(
                            player, playerIndex, gamePlayerInfo.playerId);
                      }).toList(),
                      onReorderItem: (int oldIndex, int newIndex) {
                        setState(() {
                          final PlayerGameInfo player =
                              _playersInfo.removeAt(oldIndex);
                          player.playOrderPosition = newIndex;
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
    final bool isGuest = UserProvider().loggedInUser == null;
    return Center(
      child: Card(
        elevation: isGuest ? 2 : 6,
        color: isGuest ? Colors.grey[100] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Schedule start time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isGuest ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                  ),
                  if (isGuest) ...[
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.lock, color: Colors.grey, size: 20),
                    ),
                  ]
                ],
              ),
              ListTile(
                title: FutureBuilder<String>(
                  future: Utilities.formatStartTime(
                      widget.unstartedGame!.scheduledTime),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: TextStyle(
                          color: isGuest ? Colors.grey[500] : Colors.black,
                        ),
                      );
                    } else {
                      return const Text("Loading...");
                    }
                  },
                ),
                trailing: IconButton(
                  icon: Icon(
                    isGuest ? Icons.lock_outline : Icons.schedule,
                    color: isGuest ? Colors.grey : null,
                  ),
                  onPressed:
                      isGuest ? _showGatedSchedulingDialog : _editStartTime,
                ),
                onTap: isGuest ? _showGatedSchedulingDialog : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          if (!_isCreatingGame) {
            _updateUnstartedGame();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title:
              Text('Start Game - ${widget.unstartedGame?.name ?? 'New Game'}'),
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
                onPressed: _scheduleGame,
                label: const Row(
                  children: [Icon(Icons.schedule), Text("Schedule game")],
                ),
              ),
              FloatingActionButton.extended(
                heroTag: "btnStartGame",
                onPressed: _startGame,
                label: const Row(
                  children: [
                    Icon(Icons.sports_golf_rounded),
                    Text("Start the game!")
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

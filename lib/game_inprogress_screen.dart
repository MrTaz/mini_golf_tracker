import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course_list_item_widget.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/player_profile_widget.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameInprogressScreen extends StatefulWidget {
  const GameInprogressScreen({super.key, required this.currentGame});

  final Game currentGame;

  @override
  GameInprogressScreenState createState() => GameInprogressScreenState();
}

class GameInprogressScreenState extends State<GameInprogressScreen> {
  int currentHole = 1;
  int currentHolePar = 3;
  bool gameCompleted = false;
  bool isUpdatingGame = false;
  final Player? loggedInUser = UserProvider().loggedInUser;

  late List<PlayerGameInfo> _playersInfo;

  @override
  void initState() {
    super.initState();
    _initializePlayersInfo();
    currentHole = (widget.currentGame.players[0].scores.isEmpty)
        ? 1
        : widget.currentGame.players[0].scores.length;
    currentHolePar = widget.currentGame.course.getParValue(currentHole);
  }

  void _initializePlayersInfo() {
    _playersInfo = widget.currentGame.players
        .map((player) => PlayerGameInfo(
            playerId: player.playerId,
            gameId: widget.currentGame.id,
            playOrderPosition: player.playOrderPosition ?? 0,
            scores: player.scores,
            totalScore: player.totalScore,
            place: player.place))
        .toList();
    _playersInfo.sort(
        (a, b) => a.playOrderPosition!.compareTo(b.playOrderPosition as num));
  }

  Future<void> _updateGame() async {
    // Update the currentGame with the _playersInfo data
    widget.currentGame.players
        .replaceRange(0, widget.currentGame.players.length, _playersInfo);

    // Save the updated currentGame to SharedPreferences
    await Game.saveLocalGame(widget.currentGame);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentGameJson = jsonEncode(widget.currentGame);
    await prefs.setString(widget.currentGame.id, currentGameJson);
    if (loggedInUser != null) {
      await Game.saveGameToDatabase(widget.currentGame, loggedInUser!);
    }

    if (gameCompleted && loggedInUser != null) {
      // Update each players total score when the game is complete.
      for (PlayerGameInfo player in widget.currentGame.players) {
        Player currentPlayer =
            loggedInUser!.getPlayerFriendById(player.playerId)!;
        currentPlayer.totalScore = currentPlayer.totalScore + player.totalScore;
        Player.updatePlayerScoreInDatabase(currentPlayer);
      }
      // Navigate to the PastGameDetailsScreen if the game is completed
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) {
          Utilities.debugPrintWithCallerInfo(
              "PASSING Current game: ${widget.currentGame.toJson()}");
          return PastGameDetailsScreen(passedGame: widget.currentGame);
        }),
      );
    }
  }

  Widget _buildCourseCard() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CourseListItem(
                course: widget.currentGame.course,
                onDelete: () {},
                onModify: () {}),
          ],
        ),
      ),
    );
  }


  void _setScoreForCurrentHole(PlayerGameInfo playerGameInfo, int score) {
    while (playerGameInfo.scores.length < currentHole - 1) {
      playerGameInfo.scores.add(0);
    }

    if (playerGameInfo.scores.length == currentHole - 1) {
      playerGameInfo.scores.add(score);
    } else {
      playerGameInfo.scores[currentHole - 1] = score;
    }
    _updateGame();
  }

  void _resetAllPlayersTotalScores() {
    for (var playerInfo in _playersInfo) {
      playerInfo.totalScore = 0;
    }
  }

  void _updateAllPlayersTotalScoresFromPreviousHoles() {
    // Update total scores for previous holes
    for (int hole = 0; hole < currentHole; hole++) {
      for (int i = 0; i < _playersInfo.length; i++) {
        _playersInfo[i].totalScore +=
            (_playersInfo[i].scores.isEmpty ? 6 : _playersInfo[i].scores[hole]);
      }
    }
  }

  void _setAllPlayersPlaces() {
    List<PlayerGameInfo> sortedPlayers = List.from(_playersInfo);
    sortedPlayers.sort((a, b) => a.totalScore.compareTo(b.totalScore));

    // Update the place based on sorted order
    for (int i = 0; i < sortedPlayers.length; i++) {
      sortedPlayers[i].place = Utilities.getPositionString(i);
    }
    for (int i = 0; i < sortedPlayers.length; i++) {
      if (_playersInfo[i].playerId == sortedPlayers[i].playerId) {
        _playersInfo[i].place = sortedPlayers[i].place;
      }
    }
  }

  void _handleNextHoleButton() {
    setState(() {
      for (var pgi in _playersInfo) {
        if (pgi.scores.length < currentHole || pgi.scores[currentHole - 1] == 0) {
          _setScoreForCurrentHole(pgi, 6);
        }
      }
      _resetAllPlayersTotalScores();
      _updateAllPlayersTotalScoresFromPreviousHoles();
      _setAllPlayersPlaces();
      currentHole++;
      currentHolePar = widget.currentGame.course.getParValue(currentHole);
    });
  }

  void _handleGameCompletion() {
    setState(() {
      for (var pgi in _playersInfo) {
        if (pgi.scores.length < currentHole || pgi.scores[currentHole - 1] == 0) {
          _setScoreForCurrentHole(pgi, 6);
        }
      }
      _resetAllPlayersTotalScores();
      _updateAllPlayersTotalScoresFromPreviousHoles();
      _setAllPlayersPlaces();
      for (var playerInfo in _playersInfo) {
        playerInfo.totalScore =
            playerInfo.scores.fold(0, (sum, score) => sum + score);
      }
      gameCompleted = true;
      widget.currentGame.status = "completed";
    });
  }

  Widget _buildCurrentHoleWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentHole > 1)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentHole--;
                  currentHolePar = widget.currentGame.course.getParValue(currentHole);
                });
              },
              child: const FittedBox(fit: BoxFit.fitWidth, child: Text('Prev Hole')),
            )
          else
            const SizedBox(width: 50),
          Text('Current Hole # $currentHole (Par: $currentHolePar)'),
          ElevatedButton(
            onPressed: () async {
              if (!gameCompleted) {
                if (currentHole != widget.currentGame.course.numberOfHoles) {
                  _handleNextHoleButton();
                } else {
                  _handleGameCompletion();
                }
                _updateGame();
              } else {
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) {
                    return PastGameDetailsScreen(
                        passedGame: widget.currentGame);
                  }),
                );
              }
            },
            child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  (currentHole != widget.currentGame.course.numberOfHoles)
                      ? 'Next Hole'
                      : 'Complete Game',
                  overflow: TextOverflow.clip,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
      PlayerGameInfo pgi, int playerScore, int playerScoreDropDownIndex) {
    final textScale = MediaQuery.of(context).size.height * 0.01;
    // final screenHeight = MediaQuery.of(context).size.height;

    // double getHeight(double sysVar, double size) {
    //   double calc = size / 1000;
    //   return sysVar * calc;
    // }

    double getTextSize(double sysVar, double size) {
      double calc = size / 10;
      return sysVar * calc;
    }

    String? rankString = pgi.place?.replaceAll(RegExp(r'[^\d]'), '');
    int rank = 99;
    if (rankString != '') {
      rank = int.parse(rankString ?? '99');
    }

    return Card(
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: PlayerProfileWidget(
                player: Player.empty().getPlayerFriendById(pgi.playerId)!,
                isSelected: false,
                rank: rank),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            FittedBox(
                                fit: BoxFit.fill,
                                child: Text('Current score: ${pgi.totalScore}',
                                    style: TextStyle(
                                        fontSize: getTextSize(textScale, 20)))),
                            if (currentHole != 1) ...[
                              FittedBox(
                                  fit: BoxFit.fill,
                                  child: Row(
                                    children: [
                                      Text('Last hole (${currentHole - 1}): ',
                                          style: TextStyle(
                                              fontSize:
                                                  getTextSize(textScale, 18))),
                                      Text(
                                        '${pgi.scores[currentHole - 2]}',
                                        style: TextStyle(
                                            color: (pgi.scores[
                                                        currentHole - 2] <
                                                    currentHolePar)
                                                ? Colors.green
                                                : (pgi.scores[currentHole - 2] >
                                                        currentHolePar)
                                                    ? Colors.red
                                                    : Colors.black,
                                            fontSize:
                                                getTextSize(textScale, 18)),
                                      )
                                    ],
                                  ))
                            ]
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Score'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.greenAccent,
                                    elevation: 3,
                                    shape: const CircleBorder(),
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (playerScore > 1) {
                                        playerScore--;
                                        _setScoreForCurrentHole(pgi, playerScore);
                                      } else if (playerScore == 0) {
                                        _setScoreForCurrentHole(pgi, 1);
                                      }
                                    });
                                  },
                                  child: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<int>(
                                  value: playerScore > 0 ? playerScore - 1 : null,
                                  hint: const Text('-'),
                                  items: List.generate(6, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text('${index + 1}'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value != null) {
                                        playerScore = value + 1;
                                        _setScoreForCurrentHole(pgi, playerScore);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.greenAccent,
                                    elevation: 3,
                                    shape: const CircleBorder(),
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (playerScore == 0) {
                                        _setScoreForCurrentHole(pgi, 2);
                                      } else if (playerScore < 6) {
                                        playerScore++;
                                        _setScoreForCurrentHole(pgi, playerScore);
                                      }
                                    });
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Skip/Drop", style: TextStyle(fontSize: 10)),
                                Switch(
                                  value: playerScore == 6,
                                  onChanged: (val) {
                                    setState(() {
                                      _setScoreForCurrentHole(pgi, val ? 6 : 1);
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCards() {
    return Flexible(
      fit: FlexFit.loose,
      flex: 1,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(0.8),
        itemCount: widget.currentGame.players.length,
        itemBuilder: (BuildContext context, int index) {
          PlayerGameInfo pgi = _playersInfo[index];
          int playerScore = pgi.scores.length >= currentHole
              ? pgi.scores[currentHole - 1]
              : 0;
          int playerScoreDropDownIndex =
              (playerScore <= 1) ? 0 : playerScore - 1;
          return _buildPlayerCard(pgi, playerScore, playerScoreDropDownIndex);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            _updateGame(); // Save the current game
          }
        },
        child: Scaffold(
            backgroundColor: Colors.white,
            extendBodyBehindAppBar: false,
            appBar: AppBar(
              title: Text('Let\'s Play! ${widget.currentGame.name}'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pause') {
                      _updateGame();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage(skipAutoResume: true)),
                        (route) => false,
                      );
                    } else if (value == 'end') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("End Game Early?"),
                          content: const Text("Scores will be finalized and cannot be reopened."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                _updateGame();
                                Navigator.pop(context);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage(skipAutoResume: true)),
                                  (route) => false,
                                );
                              },
                              child: const Text("Pause Game instead"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _handleGameCompletion();
                                _updateGame();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PastGameDetailsScreen(passedGame: widget.currentGame),
                                  ),
                                );
                              },
                              child: const Text("End Game"),
                            ),
                          ],
                        ),
                      );
                    } else if (value == 'abandon') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Abandon Game?"),
                          content: const Text("Strict data-loss warning. All progress will be lost."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                await prefs.remove(widget.currentGame.id);
                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage(skipAutoResume: true)),
                                  (route) => false,
                                );
                              },
                              child: const Text("Abandon Game"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pause', child: Text("Pause Game")),
                    const PopupMenuItem(value: 'end', child: Text("End Game Early")),
                    const PopupMenuItem(value: 'abandon', child: Text("Abandon Game")),
                  ],
                ),
              ],
            ),
            body: Stack(children: [
              Utilities.backdropImageContinerWidget(),
              SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height + 200,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildCourseCard(),
                        if (loggedInUser == null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.amber[100],
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Expanded(child: Text("Playing as a Guest. Sign up to save your score to the cloud!")),
                                ],
                              ),
                            ),
                          ),
                        _buildCurrentHoleWidget(),
                        _buildPlayerCards(),
                      ],
                    ),
                  ),
                ),
              ),
            ])));
  }
}

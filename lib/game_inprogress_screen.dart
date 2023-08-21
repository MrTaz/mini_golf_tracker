import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course_list_item_widget.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';
import 'package:mini_golf_tracker/player_profile_widget.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameInprogressScreen extends StatefulWidget {
  final Game currentGame;
  const GameInprogressScreen({super.key, required this.currentGame});

  @override
  GameInprogressScreenState createState() => GameInprogressScreenState();
}

class GameInprogressScreenState extends State<GameInprogressScreen> {
  final Player? loggedInUser = UserProvider().loggedInUser;
  late List<PlayerGameInfo> _playersInfo;
  int currentHole = 1;
  int currentHolePar = 3;
  bool gameCompleted = false;
  bool isUpdatingGame = false;

  @override
  void initState() {
    super.initState();
    _initializePlayersInfo();
    currentHole = (widget.currentGame.players[0].scores.isEmpty) ? 1 : widget.currentGame.players[0].scores.length;
    currentHolePar = widget.currentGame.course.getParValue(currentHole);
  }

  void _initializePlayersInfo() {
    _playersInfo = widget.currentGame.players
        .map((player) => PlayerGameInfo(
            playerId: player.playerId,
            gameId: widget.currentGame.id,
            scores: player.scores,
            totalScore: player.totalScore,
            place: player.place))
        .toList();
  }

  Future<void> _updateGame() async {
    // Update the currentGame with the _playersInfo data
    widget.currentGame.players.replaceRange(0, widget.currentGame.players.length, _playersInfo);

    // Save the updated currentGame to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentGameJson = jsonEncode(widget.currentGame);
    await prefs.setString(widget.currentGame.id, currentGameJson);
    await Game.saveGameToDatabase(widget.currentGame, loggedInUser!);

    if (gameCompleted) {
      // Update each players total score when the game is complete.
      for (PlayerGameInfo player in widget.currentGame.players) {
        Player currentPlayer = loggedInUser!.getPlayerFriendById(player.playerId)!;
        currentPlayer.totalScore = currentPlayer.totalScore + player.totalScore;
        Player.updatePlayerScoreInDatabase(currentPlayer);
      }
      // Navigate to the PastGameDetailsScreen if the game is completed
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) {
          Utilities.debugPrintWithCallerInfo("PASSING Current game: ${widget.currentGame.toJson()}");
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
            CourseListItem(course: widget.currentGame.course, onDelete: () {}, onModify: () {}),
          ],
        ),
      ),
    );
  }

  bool _checkAllPlayersScoredCurrentHole() {
    return _playersInfo.every((pgi) {
      if (pgi.scores.isEmpty) return false;
      return true; // Allow proceeding even if the score is 1
    });
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
        _playersInfo[i].totalScore += (_playersInfo[i].scores.isEmpty ? 6 : _playersInfo[i].scores[hole]);
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
      _resetAllPlayersTotalScores();
      _updateAllPlayersTotalScoresFromPreviousHoles();
      _setAllPlayersPlaces();
      currentHole++;
      currentHolePar = widget.currentGame.course.getParValue(currentHole);
    });
  }

  void _handleGameCompletion() {
    setState(() {
      _resetAllPlayersTotalScores();
      _updateAllPlayersTotalScoresFromPreviousHoles();
      _setAllPlayersPlaces();
      for (var playerInfo in _playersInfo) {
        playerInfo.totalScore = playerInfo.scores.fold(0, (sum, score) => sum + score);
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
          const SizedBox(width: 50),
          Text('Current Hole # $currentHole (Par: $currentHolePar)'),
          ElevatedButton(
            onPressed: () async {
              if (!gameCompleted) {
                if (_checkAllPlayersScoredCurrentHole()) {
                  if (currentHole != widget.currentGame.course.numberOfHoles) {
                    _handleNextHoleButton();
                  } else {
                    _handleGameCompletion();
                  }
                  _updateGame();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please record a score for all players before moving to the next hole.')),
                  );
                }
              } else {
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) {
                    return PastGameDetailsScreen(passedGame: widget.currentGame);
                  }),
                );
              }
            },
            child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  (currentHole != widget.currentGame.course.numberOfHoles) ? 'Next Hole' : 'Complete Game',
                  overflow: TextOverflow.clip,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerGameInfo pgi, int playerScore, int playerScoreDropDownIndex) {
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

    return Card(
      child: Row(
        children: [
          Container(
            width: 100,
            child: PlayerProfileWidget(
              player: Player.empty().getPlayerFriendById(pgi.playerId)!,
              isSelected: false,
              rank: int.parse(((pgi.place) ?? '99th').replaceAll(RegExp(r'[^\d]'), '')) - 1,
            ),
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
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            FittedBox(
                                fit: BoxFit.fill,
                                child: Text('Current score: ${pgi.totalScore}',
                                    style: TextStyle(fontSize: getTextSize(textScale, 20)))),
                            if (currentHole != 1) ...[
                              FittedBox(
                                  fit: BoxFit.fill,
                                  child: Row(
                                    children: [
                                      Text('Last hole (${currentHole - 1}): ',
                                          style: TextStyle(fontSize: getTextSize(textScale, 18))),
                                      Text(
                                        '${pgi.scores[currentHole - 2]}',
                                        style: TextStyle(
                                            color: (pgi.scores[currentHole - 2] < currentHolePar)
                                                ? Colors.green
                                                : (pgi.scores[currentHole - 2] > currentHolePar)
                                                    ? Colors.red
                                                    : Colors.black,
                                            fontSize: getTextSize(textScale, 18)),
                                      )
                                    ],
                                  ))
                            ]
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                                    minimumSize: const Size(40, 40),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (playerScore > 1) {
                                        playerScoreDropDownIndex = (playerScoreDropDownIndex == 0)
                                            ? playerScoreDropDownIndex
                                            : playerScoreDropDownIndex - 1;
                                        playerScore--;
                                        if (pgi.scores.isEmpty) {
                                          pgi.scores.add(playerScore);
                                        } else {
                                          pgi.scores[currentHole - 1] = playerScore;
                                        }
                                      }
                                    });
                                  },
                                  child: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<int>(
                                  value: playerScoreDropDownIndex,
                                  items: List.generate(6, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text('${index + 1}'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setState(() {
                                      if (playerScore < 7 && playerScore > 0) {
                                        playerScoreDropDownIndex = value!;
                                        playerScore = value + 1;
                                        if (pgi.scores.isEmpty) {
                                          pgi.scores.add(playerScore);
                                        } else {
                                          pgi.scores[currentHole - 1] = playerScore;
                                        }
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                                    minimumSize: const Size(40, 40),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (playerScore < 6) {
                                        playerScoreDropDownIndex++;
                                        playerScore++;
                                        if (pgi.scores.isEmpty) {
                                          pgi.scores.add(playerScore);
                                        } else {
                                          pgi.scores[currentHole - 1] = playerScore;
                                        }
                                      }
                                    });
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              ],
                            ),
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
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(0.8),
      itemCount: widget.currentGame.players.length,
      itemBuilder: (BuildContext context, int index) {
        PlayerGameInfo pgi = _playersInfo[index];
        // Initialize scores up to the current hole if needed
        while (pgi.scores.length < currentHole) {
          pgi.scores.add(1);
        }
        int playerScore = pgi.scores.isNotEmpty ? pgi.scores[currentHole - 1] : 1;
        int playerScoreDropDownIndex = (playerScore == 1) ? 0 : playerScore - 1;
        return _buildPlayerCard(pgi, playerScore, playerScoreDropDownIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _updateGame(); // Save the current game
          return true; // Return true to allow the back navigation
        },
        child: Scaffold(
            backgroundColor: Colors.white,
            extendBodyBehindAppBar: false,
            appBar: AppBar(
              title: Text('Let\'s Play! ${widget.currentGame.name}'),
            ),
            body: Stack(children: [
              Utilities.backdropImageContinerWidget(),
              SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height + 200,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildCourseCard(),
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

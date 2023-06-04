import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'game.dart';
import 'playergameinfo.dart';

class PastGameDetailsScreen extends StatefulWidget {
  final Game passedGame;

  const PastGameDetailsScreen({Key? key, required this.passedGame})
      : super(key: key); // Use the correct constructor syntax

  @override
  _PastGameDetailsScreen createState() => _PastGameDetailsScreen(passedGame);
}

class _PastGameDetailsScreen extends State<PastGameDetailsScreen> with SingleTickerProviderStateMixin {
  final Game passedGame;
  ConfettiController confettiController = ConfettiController(duration: const Duration(seconds: 2));
  static const routeName = '/gameDetails';

  _PastGameDetailsScreen(this.passedGame);

  @override
  void initState() {
    super.initState();
    // Rest of the code
    confettiController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    confettiController.dispose();
    // Rest of the code
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final passedGame = ModalRoute.of(context)!.settings.arguments as Game;
    final PlayerGameInfo winner = passedGame.getWinner();
    final int winningScore = passedGame.calculateTotalScore(winner);
    final List<PlayerGameInfo> sortedPlayerScores = passedGame.getSortedPlayerScores();

    return Scaffold(
        appBar: AppBar(
          title: Text("${passedGame.course.name} on ${passedGame.startTime}"),
        ),
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  alignment: Alignment(1, 1),
                  image: AssetImage("assets/images/loggedin_background_2.png"),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Game: ${passedGame.name}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Course Name: ${passedGame.course.name}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Number of Holes: ${passedGame.course.numberOfHoles}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Par Values:',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: passedGame.course.numberOfHoles,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      childAspectRatio: 3.0,
                    ),
                    itemBuilder: (context, index) {
                      final holeNumber = index + 1;
                      final parValue = passedGame.course.getParValue(holeNumber);
                      return Column(
                        children: [
                          Text('Hole $holeNumber', style: TextStyle(fontSize: 12)),
                          Text('Par: $parValue', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Player Scores: ${sortedPlayerScores.length} players',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: sortedPlayerScores.length, //passedGame.players.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PlayerGameInfo player = sortedPlayerScores[index];
                      return Card(
                        child: Column(
                          children: [
                            ListTile(
                              title: Text('Player ID: ${player.playerId}'),
                              trailing: Text('Total Score: ${player.totalScore}'),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: passedGame.course.numberOfHoles,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                              itemBuilder: (BuildContext context, int holeIndex) {
                                final int holeNumber = holeIndex + 1;
                                final int strokes = sortedPlayerScores[index].scores[holeIndex];
                                final int par = passedGame.course.parStrokes[holeNumber]!;
                                final int scoreDifference = (strokes ?? 0) - par;
                                final bool isUnderPar = scoreDifference < 0;
                                final String scoreDiffDisplay =
                                    scoreDifference > 0 ? '+$scoreDifference' : scoreDifference.toString();

                                Widget scoreWidget = Container(
                                  color: (strokes == 1) ? Colors.amber[200] : Colors.grey[300],
                                  child: Column(children: [
                                    Row(
                                      children: [Text('Hole $holeNumber:, par $par')],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$strokes, ',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text((scoreDifference == 0) ? "(par)" : '($scoreDiffDisplay)',
                                            style: TextStyle(
                                              color: (scoreDifference == 0)
                                                  ? Colors.black
                                                  : isUnderPar
                                                      ? Colors.green
                                                      : Colors.red,
                                            ))
                                      ],
                                    ),
                                  ]),
                                );

                                if (strokes == 1) {
                                  scoreWidget = ConfettiWidget(
                                    confettiController: confettiController,
                                    blastDirectionality: BlastDirectionality.explosive,
                                    colors: const [Colors.red, Colors.green, Colors.blue],
                                    maxBlastForce: 10,
                                    minBlastForce: 5,
                                    emissionFrequency: 0.05,
                                    numberOfParticles: 20,
                                    gravity: 1,
                                    child: scoreWidget,
                                  );
                                }

                                return scoreWidget;
                              },
                            ),
                            // ),
                          ],
                        ),
                      );
                    },
                  ),
                  // ListView.builder(
                  //   shrinkWrap: true,
                  //   physics: NeverScrollableScrollPhysics(),
                  //   itemCount: passedGame.getSortedPlayerScores().length,
                  //   itemBuilder: (context, index) {
                  //     final player = passedGame.getSortedPlayerScores()[index];
                  //     final totalScore = passedGame.calculateTotalScore(player);
                  //     return ListTile(
                  //       title: Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           Text(player.playerId.toString()),
                  //           Text('Total Score: $totalScore'),
                  //         ],
                  //       ),
                  //       subtitle: GridView.builder(
                  //         shrinkWrap: true,
                  //         physics: NeverScrollableScrollPhysics(),
                  //         itemCount: passedGame.course.numberOfHoles,
                  //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  //           crossAxisCount: 4,
                  //           mainAxisSpacing: 8.0,
                  //           crossAxisSpacing: 8.0,
                  //           childAspectRatio: 1.0,
                  //         ),
                  //         itemBuilder: (context, index) {
                  //           final holeNumber = index + 1;
                  //           debugPrint("${player.scores}, $holeNumber");
                  //           final score = player.scores[holeNumber];
                  //           final parValue = passedGame.course.getParValue(holeNumber);
                  //           final scoreDifference = score - parValue;
                  //           return Column(
                  //             children: [
                  //               Text('Score: $score'),
                  //               Text('Par: $parValue'),
                  //               Text('Difference: $scoreDifference'),
                  //             ],
                  //           );
                  //         },
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ],
        )

        // SingleChildScrollView(
        //   child: Padding(
        //     padding: EdgeInsets.all(16.0),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text('Game Name: ${passedGame.name}'),
        //         Text('Course Name: ${passedGame.course.name}'),
        //         Text('Number of Holes: ${passedGame.course.numberOfHoles}'),
        //         // Display hole par values
        //         Row(
        //           children: [
        //             for (int hole = 1; hole <= passedGame.course.numberOfHoles; hole++)
        //               Expanded(
        //                 child: Text('Hole $hole: Par ${passedGame.course.getParValue(hole)}'),
        //               ),
        //           ],
        //         ),
        //         SizedBox(height: 16.0),
        //         Text('Player Scores:'),
        //         ListView.builder(
        //           shrinkWrap: true,
        //           itemCount: passedGame.getSortedPlayerScores().length,
        //           itemBuilder: (context, index) {
        //             final player = passedGame.getSortedPlayerScores()[index];
        //             return ListTile(
        //               title: Text(player.playerId.toString()),
        //               subtitle: Text('Total Score: ${player.totalScore}'),
        //             );
        //           },
        //         ),
        //         SizedBox(height: 16.0),
        //         Text('Player Scores per Hole:'),
        //         GridView.builder(
        //           shrinkWrap: true,
        //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //             crossAxisCount: passedGame.course.numberOfHoles + 1, // +1 for the par value column
        //           ),
        //           itemCount: passedGame.course.numberOfHoles + 1, // +1 for the header row
        //           itemBuilder: (context, index) {
        //             if (index == 0) {
        //               // Header row
        //               return const Text(''); // Adjust the header content as needed
        //             } else {
        //               final holeNumber = index;
        //               return Column(
        //                 children: [
        //                   Text('Hole $holeNumber'), // Display the hole number
        //                   for (final playerScore in passedGame.getSortedPlayerScores())
        //                     Row(
        //                       children: [
        //                         Text(
        //                             'Par: ${passedGame.course.parStrokes[holeNumber - 1]}'), // Adjust the index for 0-based list
        //                         Text(
        //                             'Score: ${playerScore.scores[holeNumber]}'), // Display the player's score for the hole
        //                         Text(
        //                             'Difference: ${playerScore.scores[holeNumber] - passedGame.course.parStrokes[holeNumber - 1]!}'), // Calculate the difference from par
        //                       ],
        //                     ),
        //                 ],
        //               );
        //             }
        //           },
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        // Column(
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   mainAxisSize: MainAxisSize.min,
        //   children: <Widget>[
        //     Center(child: Text(passedGame.name)),
        //     Center(child: Text("Winning player id: ${winner.playerId} with a total score of $winningScore")),
        //     Center(child: Text("Number of players: ${passedGame.players.length.toString()}")),
        //     Center(child: Text("Course number of Holes:${passedGame.course.numberOfHoles.toString()}")),
        //     Expanded(
        //         child: ListView.builder(
        //             padding: const EdgeInsets.all(8),
        //             itemCount: passedGame.course.parStrokes.length,
        //             itemBuilder: (BuildContext context, int index) {
        //               int key = passedGame.course.parStrokes.keys.elementAt(index);
        //               return Row(children: [Text("Hole #$key, par: ${passedGame.course.parStrokes[key]}")]);
        //             })),
        //     getPlayersList(context, passedGame.players)
        //   ],
        // ),
        //   ),
        // ]))
        );
  }

  Widget getPlayersList(BuildContext context, List<PlayerGameInfo> players) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: players.length,
        itemBuilder: (BuildContext context, int index) {
          return
              // Card(
              //     child: Row(children: [
              //   Text(players[index].playerId.toString()),
              ListView.builder(
                  itemCount: players[index].scores.length,
                  itemBuilder: (context, int sindex) {
                    return ListTile(title: Text("Hole #$sindex, score: ${players[index].scores[sindex]}"));
                  });
          // ]));
        });
  }
}

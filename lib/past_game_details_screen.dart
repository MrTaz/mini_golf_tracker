import 'package:flutter/material.dart';
import 'game.dart';
import 'playergameinfo.dart';

class PastGameDetailsScreen extends StatelessWidget {
  const PastGameDetailsScreen({Key? key, required this.passedGame})
      : super(key: key); // Use the correct constructor syntax
  final Game passedGame;
  static const routeName = '/gameDetails';

  @override
  Widget build(BuildContext context) {
    // final passedGame = ModalRoute.of(context)!.settings.arguments as Game;
    final PlayerGameInfo winner = passedGame.getWinner();
    final int winningScore = passedGame.calculateTotalScore(winner);

    return Scaffold(
        appBar: AppBar(
          title: Text("${passedGame.course.name} on ${passedGame.startTime}"),
        ),
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              alignment: Alignment(1, 1),
              image: AssetImage("assets/images/loggedin_background_2.png"),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            // child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(child: Text("Winning player id: ${winner.playerId} with a total score of $winningScore")),
                Center(child: Text("Number of players: ${passedGame.players.length.toString()}")),
                Center(child: Text("Course number of Holes:${passedGame.course.numberOfHoles.toString()}")),
                Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: passedGame.course.parStrokes.length,
                        itemBuilder: (BuildContext context, int index) {
                          int key = passedGame.course.parStrokes.keys.elementAt(index);
                          return Row(children: [Text("Hole #$key, par: ${passedGame.course.parStrokes[key]}")]);
                        })),
              ],
            ),
          ),
        ));
  }
}

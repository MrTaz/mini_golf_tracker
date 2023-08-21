import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/past_game_list_item.dart';
import 'package:mini_golf_tracker/utilities.dart';

class PastGameCardWidget extends StatefulWidget {
  const PastGameCardWidget({Key? key}) : super(key: key);

  @override
  PastGameCardWidgetState createState() => PastGameCardWidgetState();
}

class PastGameCardWidgetState extends State<PastGameCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        color: const Color.fromARGB(161, 255, 255, 255),
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              const ListTile(title: Text('Past games')),
              FutureBuilder<List<Game?>>(
                future: Game.getLocallySavedGames(gameStatusTypes: ["completed"]),
                builder: (BuildContext context, AsyncSnapshot<List<Game?>> gameSnapshot) {
                  if (gameSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (gameSnapshot.hasError) {
                    Utilities.debugPrintWithCallerInfo(gameSnapshot.error.toString());
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Error: Unable to load local game data'),
                      ],
                    );
                  } else if (gameSnapshot.hasData && gameSnapshot.data != null && gameSnapshot.data!.isNotEmpty) {
                    return Column(
                      children: <Widget>[
                        ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(0.8),
                          itemCount: gameSnapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            Game game = gameSnapshot.data![index]!;
                            return InkWell(
                              onTap: () => {
                                Utilities.debugPrintWithCallerInfo("game tapped: $index"),
                              },
                              child: PastGameListItem(
                                pastGame: game, 
                                onPastGameCardTap: (value) => {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                                    return PastGameDetailsScreen(passedGame: game);
                                  }))
                                },
                              )
                            );
                          }
                        ),
                      ],
                    );
                  } else {
                    // If no saved game exists, show the option to create a new game
                    return const Text("Let's play mini-golf!");
                  }
                },
              ),
            ]
          ),
        ),
      )
    );
  }
}
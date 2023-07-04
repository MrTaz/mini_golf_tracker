import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart'; // Replace with the actual import path for the Game class

import 'create_game_screen.dart';

class DashboardNewGameCard extends StatefulWidget {
  const DashboardNewGameCard({Key? key}) : super(key: key);

  @override
  _DashboardNewGameCardState createState() => _DashboardNewGameCardState();
}

class _DashboardNewGameCardState extends State<DashboardNewGameCard> {
  Future<bool> hasSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('unstarted_game'); // Assuming 'unstarted_game' is the key for the saved game
  }

  Future<Game?> getSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGameJson = prefs.getString('unstarted_game');
    if (savedGameJson != null && savedGameJson.isNotEmpty) {
      return Game.fromJson(savedGameJson);
    }
    return null;
  }

  Future<void> deleteSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('unstarted_game'); // Assuming 'unstarted_game' is the key for the saved game
    setState(() {}); // Refresh the widget after deletion
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: hasSavedGame(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData && snapshot.data!) {
          // If a saved game exists, show the game details
          return FutureBuilder<Game?>(
            future: getSavedGame(),
            builder: (BuildContext context, AsyncSnapshot<Game?> gameSnapshot) {
              if (gameSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (gameSnapshot.hasData && gameSnapshot.data != null) {
                Game game = gameSnapshot.data!;
                return Center(
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                                "${game.name} - ${(DateTime.now().isAfter(game.startTime)) ? "Started at" : "Scheduled for"} ${game.startTime}"),
                            subtitle: Text(
                                'Course: ${game.course.name} (${game.course.numberOfHoles} holes) - ${game.players.length} players'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: () {
                                  // Start the saved game
                                },
                                child: const Text('Start Game'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  deleteSavedGame().then((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Deleted saved game')),
                                    );
                                  });
                                },
                                child: const Text('Delete Game'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Handle the case when there's an error or the saved game data is invalid
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Error: Unable to load saved game data'),
                      ElevatedButton(
                        onPressed: () {
                          deleteSavedGame().then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Deleted saved game')),
                            );
                          });
                        },
                        child: const Text('Delete Game'),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        } else {
          // If no saved game exists, show the option to create a new game
          return Center(
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text('Create a new game'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return const CreateGameScreen();
                              }),
                            ).then((_) {
                              setState(() {}); // Refresh the widget after creating a new game
                            });
                          },
                          child: Row(
                            children: const [
                              Icon(
                                Icons.add,
                                size: 24.0,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text('New Game'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

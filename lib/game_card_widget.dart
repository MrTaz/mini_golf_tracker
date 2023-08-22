import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameCardWidget extends StatefulWidget {
  const GameCardWidget({Key? key}) : super(key: key);

  @override
  GameCardWidgetState createState() => GameCardWidgetState();
}

class GameCardWidgetState extends State<GameCardWidget> {
  @override
  void initState() {
    setState(() {}); // Refresh the widget after creating a new game
    super.initState();
  }

  updateGameCard() async {
    await Game.getLocallySavedGames(gameStatusTypes: ["unstarted_game", "started"]);
    setState(() {});
  }

  Future<void> deleteSavedGame({Game? gameToDelete}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (gameToDelete != null) {
      await prefs.remove(gameToDelete.id);
    } else {
      final Set<String> keys = prefs.getKeys().cast<String>();
      for (String key in keys) {
        dynamic value = prefs.get(key);
        Utilities.debugPrintWithCallerInfo("Found shared preference: $key $value");
        if (value is String) {
          try {
            jsonDecode(value);
            prefs.remove(key);
          } catch (e) {
            Utilities.debugPrintWithCallerInfo("Not a JSON-formatted string. Plain value: $value");
          }
        } else if (value is List<String>) {
          Utilities.debugPrintWithCallerInfo("It's a List of strings: $value");
        } else {
          Utilities.debugPrintWithCallerInfo("Value cannot be parsed. Type: ${value.runtimeType}");
        }
      }
    }
    setState(() {}); // Refresh the widget after deletion
  }

  Future<void> _navigateToGameCreateScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return GameStartScreen(callback: () {
          updateGameCard();
        });
      }),
    );
    await Game.getLocallySavedGames(gameStatusTypes: ["unstarted_game", "started"]);
    setState(() {}); // Refresh the widget after creating a new game
  }

  Widget _buildCreateNewGameCard() {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text('Create a new game'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _navigateToGameCreateScreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Game?>>(
            future: Game.getLocallySavedGames(gameStatusTypes: ["unstarted_game", "started"]),
            builder: (BuildContext context, AsyncSnapshot<List<Game?>> gameSnapshot) {
              if (gameSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (gameSnapshot.hasError) {
                Utilities.debugPrintWithCallerInfo(gameSnapshot.error.toString());
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('Error: Unable to load saved game data'),
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
                          return Card(
                              elevation: 6,
                              child: Column(children: [
                                ListTile(
                                  title: Text(
                                      "${game.name} - ${(game.status != "unstarted_game" && game.startTime != null) ? "Started at ${Utilities.formatStartTime(game.startTime!)}" : "Scheduled for ${Utilities.formatStartTime(game.scheduledTime)}"}"),
                                  subtitle: Text(
                                      'Course: ${game.course.name} (${game.course.numberOfHoles} holes) - ${game.players.length} players'),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    if (game.status == "unstarted_game") ...[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (context) {
                                                return GameStartScreen(unstartedGame: game);
                                              }),
                                            ).then((_) {
                                              setState(() {}); // Refresh the widget after creating a new game
                                            });
                                          },
                                          child: const Text('Start Game'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (game.status == "started") ...[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (context) {
                                                return GameInprogressScreen(currentGame: game);
                                              }),
                                            ).then((_) {
                                              setState(() {}); // Refresh the widget after creating a new game
                                            });
                                          },
                                          child: const Text('Continue Game'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          deleteSavedGame(gameToDelete: game).then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Deleted saved game')),
                                            );
                                          });
                                        },
                                        child: const Text('Delete Game'),
                                      ),
                                    ),
                                  ],
                                )
                              ]));
                        }),
                    _buildCreateNewGameCard(),
                  ],
                );
              } else {
                // If no saved game exists, show the option to create a new game
                return Center(child: _buildCreateNewGameCard());
              }
            },
          ),
        ),
      ),
    );
  }
}

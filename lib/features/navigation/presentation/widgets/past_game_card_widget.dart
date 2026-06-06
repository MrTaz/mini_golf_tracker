import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/past_game_details_screen.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/widgets/past_game_list_item.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

class PastGameCardWidget extends StatefulWidget {
  final Future<List<Game?>>? gamesFuture;
  const PastGameCardWidget({super.key, this.gamesFuture});

  @override
  PastGameCardWidgetState createState() => PastGameCardWidgetState();
}

class PastGameCardWidgetState extends State<PastGameCardWidget> {
  late Future<List<Game?>> _localGamesFuture;

  @override
  void initState() {
    super.initState();
    _loadLocalGames();
  }

  @override
  void didUpdateWidget(PastGameCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gamesFuture != oldWidget.gamesFuture) {
      _loadLocalGames();
    }
  }

  void _loadLocalGames() {
    _localGamesFuture = widget.gamesFuture ??
        Game.getLocallySavedGames(gameStatusTypes: ["completed"]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
      elevation: 0,
      color: const Color.fromARGB(161, 255, 255, 255),
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: <Widget>[
          const ListTile(title: Text('Past games')),
          FutureBuilder<List<Game?>>(
            future: _localGamesFuture,
            builder: (BuildContext context,
                AsyncSnapshot<List<Game?>> gameSnapshot) {
              if (gameSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (gameSnapshot.hasError) {
                Utilities.debugPrintWithCallerInfo(
                    gameSnapshot.error.toString());
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Error: Unable to load local game data'),
                  ],
                );
              } else if (gameSnapshot.hasData &&
                  gameSnapshot.data != null &&
                  gameSnapshot.data!.isNotEmpty) {
                return Column(
                  children: <Widget>[
                    ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(0.8),
                        itemCount: gameSnapshot.data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          Game game = gameSnapshot.data![index]!;
                          return PastGameListItem(
                            pastGame: game,
                            onPastGameCardTap: (value) {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return PastGameDetailsScreen(passedGame: game);
                              }));
                            },
                          );
                        }),
                  ],
                );
              } else {
                // If no saved game exists, show the option to create a new game
                return const Text("Let's play mini-golf!");
              }
            },
          ),
        ]),
      ),
    ));
  }
}

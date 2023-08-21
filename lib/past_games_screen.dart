import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/past_game_list_item.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';

import 'utilities.dart';

class PastGamesScreen extends StatefulWidget {
  final Game? currentlySelectedGame;

  const PastGamesScreen({Key? key, this.currentlySelectedGame}) : super(key: key);

  @override
  PastGameScreenState createState() => PastGameScreenState();
}

class PastGameScreenState extends State<PastGamesScreen> {
  final Player? loggedInUser = UserProvider().loggedInUser;
  List<Game> pastGames = [];

  _loadPastGames() async {
    List<Game?> loadedPastGames = await Game.getLocallySavedGames(gameStatusTypes: ["completed"]);
    List<Game> filteredLoadedPastGames = loadedPastGames.whereType<Game>().toList();
    setState(() {
      pastGames.addAll(filteredLoadedPastGames); // Update the courses list after loading
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPastGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: null,
      body: Stack(children: [
        Utilities.backdropImageContinerWidget(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(0.8),
                    itemCount: pastGames.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (pastGames.isNotEmpty) {
                        bool isSelected = widget.currentlySelectedGame == pastGames[index];
                        return _buildPastGameListItem(index, isSelected);
                      }
                      return null;
                    })
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPastGameListItem(int index, bool isSelected) {
    return PastGameListItem(
      key: Key('pastgame-$index'),
      pastGame: pastGames[index],
      isSelected: isSelected,
      onPastGameCardTap: (value) => {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return PastGameDetailsScreen(passedGame: pastGames[index]);
        }))
      },
    );
  }
}

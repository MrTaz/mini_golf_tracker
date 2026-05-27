// import 'package:calendarific_dart/calendarific_dart.dart';
import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';

class PastGamesListView extends StatefulWidget {
  const PastGamesListView({super.key});

  @override
  State<PastGamesListView> createState() => _PastGamesListViewState();
}

class _PastGamesListViewState extends State<PastGamesListView> {
  Player? loggedInUser;
  final List<Game> previousGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loggedInUser = UserProvider().loggedInUser;
    _loadGames();
  }

  Future<void> _loadGames() async {
    if (loggedInUser == null) {
      return;
    }
    try {
      Utilities.debugPrintWithCallerInfo(
          'Loading games for user ${loggedInUser!.playerName}');
      List<Game> retrievedGames =
          await Game.fetchGamesForCurrentUser(loggedInUser!.id);
      Utilities.debugPrintWithCallerInfo(
          'Retrieved Games loaded ${retrievedGames.length}');
      if (mounted) {
        setState(() {
          previousGames.addAll(retrievedGames);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget getGames(BuildContext context) {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (previousGames.isNotEmpty) {
      return Expanded(
          child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: previousGames.length,
        itemBuilder: (BuildContext context, int index) {
          // Utilities.debugPrintWithCallerInfo("Current Game: ${previousGames[index].toJson()}");
          return FutureBuilder<String>(
            future: Future.value(
                Utilities.formatStartTime(previousGames[index].startTime!)),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return InkWell(
                    onTap: () => {
                          // Utilities.debugPrintWithCallerInfo("game tapped: $index"),
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return PastGameDetailsScreen(
                                passedGame: previousGames[index]);
                          }))
                        },
                    child: SizedBox(
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(previousGames[index]
                                      .course
                                      .name), // Game Name
                                  Text(
                                      "Number of Players: ${previousGames[index].players.length.toString()}",
                                      style: const TextStyle(
                                          fontSize: 8.0)), //Winners
                                  Builder(
                                    builder: (context) {
                                      final winners = previousGames[index].getWinners();
                                      final nicknames = winners.map((p) {
                                        if (loggedInUser != null && p.playerId == loggedInUser!.id) {
                                          return loggedInUser!.nickname;
                                        }
                                        return loggedInUser?.getPlayerFriendById(p.playerId)?.nickname ?? "Unknown";
                                      }).toList();
                                      final nicknamesStr = nicknames.join(', ');
                                      final winnerLabel = winners.length > 1 ? 'Winners: $nicknamesStr' : 'Winner: $nicknamesStr';
                                      return Text(winnerLabel);
                                    },
                                  )
                                ]),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    snapshot.data ?? "",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w300,
                                        fontStyle: FontStyle.italic),
                                  )
                                ])
                          ],
                        )));
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return const CircularProgressIndicator();
              }
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ));
    } else {
      return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width * 0.9,
          child: const Align(
              alignment: Alignment.center, child: Text("Let's play!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loggedInUser == null) {
      throw "Loading Past Games: User is not logged in";
    }
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
                  Row(
                    children: <Widget>[
                      getGames(context),
                    ],
                  )
                ],
              ),
            )));
  }
}

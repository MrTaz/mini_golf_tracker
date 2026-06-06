// import 'package:calendarific_dart/calendarific_dart.dart';
import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/past_game_details_screen.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

class PastGamesListView extends StatefulWidget {
  const PastGamesListView({
    super.key,
    @visibleForTesting this.startTimeFormatter,
  });

  /// Optional override for formatting start time — used in tests only.
  final Future<String> Function(DateTime)? startTimeFormatter;

  @override
  State<PastGamesListView> createState() => _PastGamesListViewState();
}

class _PastGamesListViewState extends State<PastGamesListView> {
  Player? loggedInUser;
  final List<Game> previousGames = [];
  bool _isLoading = true;
  bool _isOffline = false;

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
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });
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
      _isOffline = true;
      try {
        final localGames = await Game.getLocallySavedGames();
        final filteredLocal = localGames
            .whereType<Game>()
            .where((g) =>
                g.status == 'completed' &&
                g.players.any((p) => p.playerId == loggedInUser!.id))
            .toList();
        if (mounted) {
          setState(() {
            previousGames.addAll(filteredLocal);
            _isLoading = false;
          });
        }
      } catch (localError) {
        // coverage:ignore-start
        // This branch only executes if SharedPreferences.getInstance() throws
        // (a platform channel failure), which cannot be simulated through the
        // standard SharedPreferences mock setup in unit tests.
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // coverage:ignore-end
      }
    }
  }

  Future<String> _formatStartTime(DateTime startTime) {
    final formatter = widget.startTimeFormatter ?? Utilities.formatStartTime;
    return formatter(startTime);
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
            future: _formatStartTime(previousGames[index].startTime!),
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
                                      final winners =
                                          previousGames[index].getWinners();
                                      final nicknames = winners.map((p) {
                                        if (loggedInUser != null &&
                                            p.playerId == loggedInUser!.id) {
                                          return loggedInUser!.nickname;
                                        }
                                        return loggedInUser
                                                ?.getPlayerFriendById(
                                                    p.playerId)
                                                ?.nickname ??
                                            "Unknown";
                                      }).toList();
                                      final nicknamesStr = nicknames.join(', ');
                                      final winnerLabel = winners.length > 1
                                          ? 'Winners: $nicknamesStr'
                                          : 'Winner: $nicknamesStr';
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
      return Expanded(
          child: Center(
              child: Text(
                  _isOffline
                      ? "We couldn't sync your past games. Please check your internet connection."
                      : "Let's play!",
                  textAlign: TextAlign.center)));
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
                  if (_isOffline)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off,
                                color: Colors.amber.shade800, size: 16),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                "Offline mode: showing locally saved games. Connect to the internet to sync and view your cloud history.",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

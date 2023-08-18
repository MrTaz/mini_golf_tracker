import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'course_list_item_widget.dart';
import 'game.dart';
import 'player.dart';
import 'player_score_data_table_card.dart';
import 'player_game_info.dart';
import 'players_card_widget.dart';

class PastGameDetailsScreen extends StatefulWidget {
  final Game passedGame;

  const PastGameDetailsScreen({Key? key, required this.passedGame}) : super(key: key);

  @override
  PastGameDetailsScreenState createState() => PastGameDetailsScreenState();
}

class PastGameDetailsScreenState extends State<PastGameDetailsScreen> with SingleTickerProviderStateMixin {
  ConfettiController confettiController = ConfettiController(duration: const Duration(seconds: 2));
  static const routeName = '/gameDetails';
  List<Player> clickedPlayer = [];
  List<PlayerGameInfo> clickedPlayerScores = [];
  List<PlayerGameInfo> sortedPlayerScores = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    sortedPlayerScores = widget.passedGame.getSortedPlayerScores();
    Utilities.debugPrintWithCallerInfo("Passed in game: ${widget.passedGame.toJson()}");
    confettiController.addListener(() {
      setState(() {});
    });
    // _scrollController = ScrollController();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text("${widget.passedGame.course.name} on ${widget.passedGame.startTime!}"),
        ),
        body: FutureBuilder<String>(
          future: Future.value(Utilities.formatStartTime(widget.passedGame.startTime!)),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  Utilities.backdropImageContinerWidget(),
                  ListView(controller: _scrollController, children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(
                            'Game: ${widget.passedGame.name}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            snapshot.data ?? "",
                            style:
                                const TextStyle(fontSize: 15, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
                          ),
                        ),
                        CourseListItem(course: widget.passedGame.course, onDelete: () {}, onModify: () {}),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                  PlayersCard(
                                      cardTitle: "Players: ${sortedPlayerScores.length} players",
                                      sortedPlayerIds: sortedPlayerScores.map((gameInfo) => gameInfo.playerId).toList(),
                                      onTap: handlePlayerClick),
                                ]))),
                        Flexible(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                      const Text(
                                        'Player Scores',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      PlayerScoreDataTable(
                                          clickedPlayers: clickedPlayer,
                                          clickedPlayerScores: clickedPlayerScores,
                                          game: widget.passedGame)
                                    ])))),
                      ],
                    ),
                  ]),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ));
  }

  // Widget getPlayersList(BuildContext context, List<PlayerGameInfo> players) {
  //   return ListView.builder(
  //       padding: const EdgeInsets.all(8),
  //       itemCount: players.length,
  //       itemBuilder: (BuildContext context, int index) {
  //         return ListView.builder(
  //             itemCount: players[index].scores.length,
  //             itemBuilder: (context, int sindex) {
  //               return ListTile(title: Text("Hole #$sindex, score: ${players[index].scores[sindex]}"));
  //             });
  //       });
  // }

  PlayerGameInfo? _getPlayerGameInfo(int playerId) {
    return sortedPlayerScores.firstWhere((gameInfo) => gameInfo.playerId == playerId,
        orElse: () => throw Exception("No PlayerGameInfo found for playerId: $playerId"));
  }

  void handlePlayerClick(Player player) {
    setState(() {
      _scrollController.animateTo(
        100,
        curve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 500),
      );
      if (clickedPlayer.contains(player)) {
        clickedPlayer.remove(player);
        clickedPlayerScores.remove(_getPlayerGameInfo(player.id));
      } else {
        clickedPlayer.add(player);
        var currentClickPlayerGameInfo = _getPlayerGameInfo(player.id);
        if (currentClickPlayerGameInfo != null) {
          clickedPlayerScores.add(currentClickPlayerGameInfo);
        }
      }
    });
  }
}

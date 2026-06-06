import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/widgets/app_drawer_widget.dart';
import 'package:mini_golf_tracker/features/courses/presentation/widgets/course_list_item_widget.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';
import 'package:mini_golf_tracker/features/gameplay/presentation/widgets/player_score_data_table_card.dart';
import 'package:mini_golf_tracker/features/players/presentation/widgets/players_card_widget.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

class PastGameDetailsScreen extends StatefulWidget {
  const PastGameDetailsScreen({super.key, required this.passedGame});

  final Game passedGame;

  @override
  PastGameDetailsScreenState createState() => PastGameDetailsScreenState();
}

class PastGameDetailsScreenState extends State<PastGameDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const routeName = '/gameDetails';

  List<Player> clickedPlayer = [];
  List<PlayerGameInfo> clickedPlayerScores = [];
  ConfettiController confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  List<PlayerGameInfo> sortedPlayerScores = [];

  final ScrollController _scrollController = ScrollController();

  void _confettiListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    confettiController.removeListener(_confettiListener);
    confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    sortedPlayerScores = widget.passedGame.getSortedPlayerScores();
    clickedPlayerScores = List.from(sortedPlayerScores);
    for (var info in sortedPlayerScores) {
      Player? player = Player.empty().getPlayerFriendById(info.playerId);
      if (player?.id == '' &&
          UserProvider().loggedInUser?.id == info.playerId) {
        player = UserProvider().loggedInUser;
      }
      if (player != null) {
        clickedPlayer.add(player);
      }
    }

    Utilities.debugPrintWithCallerInfo(
        "Passed in game: ${widget.passedGame.toJson()}");
    confettiController.addListener(_confettiListener);
    // _scrollController = ScrollController();
  }

  void handlePlayerClick(Player player) {
    setState(() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          100,
          curve: Curves.fastOutSlowIn,
          duration: const Duration(milliseconds: 500),
        );
      }
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

  PlayerGameInfo? _getPlayerGameInfo(String playerId) {
    return sortedPlayerScores.firstWhere(
        (gameInfo) => gameInfo.playerId == playerId,
        orElse: () =>
            throw Exception("No PlayerGameInfo found for playerId: $playerId"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(
              "${widget.passedGame.course.name} on ${widget.passedGame.startTime!}"),
        ),
        body: FutureBuilder<String>(
          future: Future.value(
              Utilities.formatStartTime(widget.passedGame.startTime!)),
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
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            snapshot.data ?? "",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w300,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                        CourseListItem(
                            course: widget.passedGame.course,
                            onDelete: () {},
                            onModify: () {}),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                  PlayersCard(
                                      cardTitle:
                                          "Players: ${sortedPlayerScores.length} players",
                                      sortedPlayerIds: sortedPlayerScores
                                          .map((gameInfo) => gameInfo.playerId)
                                          .toList(),
                                      onTap: handlePlayerClick),
                                ]))),
                        Flexible(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                      const Text(
                                        'Player Scores',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      PlayerScoreDataTable(
                                          clickedPlayers: clickedPlayer,
                                          clickedPlayerScores:
                                              clickedPlayerScores,
                                          game: widget.passedGame)
                                    ])))),
                      ],
                    ),
                  ]),
                ],
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ));
  }
}

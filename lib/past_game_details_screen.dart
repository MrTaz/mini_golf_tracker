import 'package:confetti/confetti.dart';
import 'package:calendarific_dart/calendarific_dart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  List<Player> gamePlayers = [];
  List<PlayerGameInfo> sortedPlayerScores = [];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    gamePlayers = Player.getAllPlayers();
    sortedPlayerScores = widget.passedGame.getSortedPlayerScores();

    confettiController.addListener(() {
      setState(() {});
    });
    initializeDateFormatting(); // Initialize intl package
    // _scrollController = ScrollController();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final passedGame = ModalRoute.of(context)!.settings.arguments as Game;
    // final PlayerGameInfo winner = passedGame.getWinner();
    // final int winningScore = passedGame.calculateTotalScore(winner);
    // final formattedStartTime = formatStartTime(passedGame.startTime);
    // final List<PlayerGameInfo> sortedPlayerScores = passedGame.getSortedPlayerScores();

    return Scaffold(
        appBar: AppBar(
          title: Text("${widget.passedGame.course.name} on ${widget.passedGame.startTime}"),
        ),
        backgroundColor: Colors.white,
        body: FutureBuilder<String>(
          future: formatStartTime(widget.passedGame.startTime),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView(
                controller: _scrollController,
                children: [
                  Container(
                    width: double.infinity,
                    // height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        alignment: Alignment(1, 1),
                        image: AssetImage("assets/images/loggedin_background_2.png"),
                      ),
                    ),
                    child: Column(
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
                        ExpansionTile(
                            title: Text(
                              'Course: ${widget.passedGame.course.name}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            children: [
                              ListTile(
                                title: Text('Number of Holes: ${widget.passedGame.course.numberOfHoles}'),
                              ),
                              ListTile(
                                  title: const Text('Par Values:', style: TextStyle(fontSize: 16)),
                                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: widget.passedGame.course.numberOfHoles,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 8.0,
                                        crossAxisSpacing: 8.0,
                                        childAspectRatio: 3.0,
                                      ),
                                      itemBuilder: (context, index) {
                                        final holeNumber = index + 1;
                                        final parValue = widget.passedGame.course.getParValue(holeNumber);
                                        return Column(
                                          children: [
                                            Text('Hole $holeNumber', style: const TextStyle(fontSize: 12)),
                                            Text('Par: $parValue', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        );
                                      },
                                    )
                                  ]))
                            ]),
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
                  ),
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

  Widget getPlayersList(BuildContext context, List<PlayerGameInfo> players) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: players.length,
        itemBuilder: (BuildContext context, int index) {
          return ListView.builder(
              itemCount: players[index].scores.length,
              itemBuilder: (context, int sindex) {
                return ListTile(title: Text("Hole #$sindex, score: ${players[index].scores[sindex]}"));
              });
        });
  }

  Future<String> formatStartTime(DateTime startTime) async {
    final now = DateTime.now();
    final daysDifference = now.difference(startTime).inDays;
    final timeFormatter = DateFormat.jm();
    const String apiKey = '';
    final CalendarificApi api = CalendarificApi(apiKey);
    const String countryCode = "US";
    String formattedResponse = "";

    if (daysDifference <= 30) {
      formattedResponse = '$daysDifference day(s) ago @ ${timeFormatter.format(startTime)}';
    } else {
      final formatter = DateFormat.yMMMMd('en_US');
      formattedResponse = '${formatter.format(startTime)} @ ${timeFormatter.format(startTime)}';
    }

    // final holidays = await api.getHolidays(countryCode: countryCode, year: startTime.year.toString());

    // if (holidays != null && holidays.isNotEmpty) {
    //   final Holiday? holiday = holidays.firstWhere(
    //     (h) => h.date.day == startTime.day && h.date.month == startTime.month,
    //     orElse: () => null as Holiday,
    //   );

    //   if (holiday != null) {
    //     return '$formattedResponse - ${holiday.name}';
    //   } else {
    //     return formattedResponse;
    //   }
    // } else {
    return formattedResponse;
    // }
  }

  PlayerGameInfo? _getPlayerGameInfo(int playerId) {
    return sortedPlayerScores.firstWhere((gameInfo) => gameInfo.playerId == playerId,
        orElse: () => null as PlayerGameInfo);
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

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_game_info.dart';

class PlayerScoreDataTable extends StatefulWidget {
  final List<Player> clickedPlayers;
  final List<PlayerGameInfo> clickedPlayerScores;
  final Game game;

  const PlayerScoreDataTable({
    Key? key,
    required this.clickedPlayers,
    required this.clickedPlayerScores,
    required this.game,
  }) : super(key: key);

  @override
  PlayerScoreDataTableState createState() => PlayerScoreDataTableState();
}

class PlayerScoreDataTableState extends State<PlayerScoreDataTable> {
  @override
  Widget build(BuildContext context) {
    if (widget.clickedPlayers.isEmpty) {
      return const Center(
        child: Text('No players selected.'),
      );
    }
    // widget.clickedPlayers
    //     .forEach((element) => Utilities.debugPrintWithCallerInfo('Clicked Player: ${widget.clickedPlayers} ${element.toJson()}'));
    // widget.clickedPlayerScores
    //     .forEach((element) => Utilities.debugPrintWithCallerInfo('Clicked Player Scores: ${widget.clickedPlayerScores} ${element.toJson()}'));

    return Container(
        height: 48.0 * (widget.game.course.numberOfHoles + 2),
        color: Colors.white.withOpacity(0.8),
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 24.0,
              columns: _buildColumns(),
              rows: _buildRows(),
            ),
          ),
        ));
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [];

    columns.add(
      const DataColumn(
        label: Text('Hole'),
        numeric: true,
      ),
    );

    for (final player in widget.clickedPlayers) {
      final playerGameInfo = widget.clickedPlayerScores
          .firstWhere((pgi) => pgi.playerId == player.id, orElse: () => null as PlayerGameInfo);
      if (playerGameInfo != null) {
        columns.add(
          DataColumn(
            label: Text('${player.nickname}\n${playerGameInfo.place}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
        );

        columns.add(
          const DataColumn(
            label: Text(
              'Total',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),
            ),
            numeric: true,
          ),
        );
      }
    }

    return columns;
  }

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];
    final maxScores = _getMaxScores();

    for (var i = 0; i < maxScores; i++) {
      List<DataCell> cells = [];

      final holeNumber = i + 1;
      final holePar = widget.game.course.getParValue(holeNumber);

      cells.add(
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text('$holeNumber ($holePar)'),
          ),
        ),
      );

      for (final player in widget.clickedPlayers) {
        final playerGameInfo = widget.clickedPlayerScores
            .firstWhere((pgi) => pgi.playerId == player.id, orElse: () => null as PlayerGameInfo);
        if (i < playerGameInfo.scores.length) {
          final score = playerGameInfo.scores[i];
          final difference = score - holePar;

          final differenceText = difference == 0
              ? ""
              : difference >= 0
                  ? '(+$difference)'
                  : '($difference)';
          final differenceColor = difference == 0
              ? Colors.black
              : difference >= 0
                  ? Colors.red
                  : Colors.green;

          cells.add(
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$score $differenceText',
                  style: TextStyle(color: differenceColor),
                ),
              ),
            ),
          );

          final cumulativeScore = _getCumulativeScore(playerGameInfo.scores, i);
          cells.add(
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  cumulativeScore.toString(),
                ),
              ),
            ),
          );
        } else {
          cells.add(
            const DataCell(
              Text(''),
            ),
          );
          cells.add(
            const DataCell(
              Text(''),
            ),
          );
        }
      }

      rows.add(
        DataRow(cells: cells),
      );
    }

    // Add the total score row
    List<DataCell> totalScoreCells = [];
    totalScoreCells.add(
      const DataCell(
        Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
    for (final player in widget.clickedPlayers) {
      final playerGameInfo = widget.clickedPlayerScores
          .firstWhere((pgi) => pgi.playerId == player.id, orElse: () => null as PlayerGameInfo);
      if (playerGameInfo != null) {
        final totalScore = _getTotalScore(playerGameInfo.scores);
        totalScoreCells.add(
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                totalScore.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );

        totalScoreCells.add(
          const DataCell(
            Text(''),
          ),
        );
      }
    }
    rows.add(
      DataRow(cells: totalScoreCells),
    );

    return rows;
  }

  int _getMaxScores() {
    int maxScores = 0;

    for (final playerGameInfo in widget.clickedPlayerScores) {
      if (playerGameInfo.scores.length > maxScores) {
        maxScores = playerGameInfo.scores.length;
      }
    }

    return maxScores;
  }

  int _getCumulativeScore(List<int> scores, int currentIndex) {
    int cumulativeScore = 0;
    for (var i = 0; i <= currentIndex; i++) {
      cumulativeScore += scores[i];
    }
    return cumulativeScore;
  }

  int _getTotalScore(List<int> scores) {
    int totalScore = 0;
    for (final score in scores) {
      totalScore += score;
    }
    return totalScore;
  }
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/player_game_info.dart';

void main() {
  group('Course', () {
    test('round trips database JSON shape', () {
      final course = Course(
        id: "7",
        name: 'Putter Park',
        numberOfHoles: 3,
        parStrokes: {1: 2, 2: 3, 3: 4},
      );

      final dbJson = {
        'id': '7',
        'name': 'Putter Park',
        'number_of_holes': 3,
        'par_strokes': {'1': 2, '2': 3, '3': 4},
        'latitude': null,
        'longitude': null,
        'address': null,
        'locationName': null,
      };
      expect(course.toJson(), dbJson);

      final decoded = Course.fromJson(course.toJson());

      expect(decoded.id, "7");
      expect(decoded.name, 'Putter Park');
      expect(decoded.numberOfHoles, 3);
      expect(decoded.parStrokes, {1: 2, 2: 3, 3: 4});
      expect(decoded.latitude, null);
      expect(decoded.longitude, null);
      expect(decoded.address, null);
    });

    test('throws for invalid hole number', () {
      final course = Course(
        id: "1",
        name: 'Short Course',
        numberOfHoles: 1,
        parStrokes: {1: 2},
      );

      expect(() => course.getParValue(2), throwsException);
    });

    test('copyWith updates fields', () {
      final course = Course(
        id: "7",
        name: 'Putter Park',
        numberOfHoles: 1,
        parStrokes: {1: 2},
      );
      final updated = course.copyWith(
        id: "8",
        name: 'New Park',
        numberOfHoles: 2,
        parStrokes: {1: 3, 2: 4},
        latitude: 10.0,
        longitude: 20.0,
        address: '123 Test St',
        locationName: 'Test Location',
      );
      expect(updated.id, '8');
      expect(updated.name, 'New Park');
      expect(updated.numberOfHoles, 2);
      expect(updated.parStrokes, {1: 3, 2: 4});
      expect(updated.latitude, 10.0);
      expect(updated.longitude, 20.0);
      expect(updated.address, '123 Test St');
      expect(updated.locationName, 'Test Location');

      // Test null inputs use existing values
      final same = updated.copyWith();
      expect(same.id, '8');
      expect(same.name, 'New Park');
      expect(same.numberOfHoles, 2);
      expect(same.parStrokes, {1: 3, 2: 4});
      expect(same.latitude, 10.0);
      expect(same.longitude, 20.0);
      expect(same.address, '123 Test St');
      expect(same.locationName, 'Test Location');
    });

    test('fromJson parses string doubles and ints', () {
      final json = {
        'id': '9',
        'name': 'Parse Park',
        'number_of_holes': 1,
        'par_strokes': {'1': 3.5, '2': 'invalid', '3': '4.5'},
        'latitude': 10,
        'longitude': 20.5,
      };
      final parsed = Course.fromJson(json);
      expect(parsed.parStrokes, {1: 3, 3: 4});
      expect(parsed.latitude, 10.0);
      expect(parsed.longitude, 20.5);
    });
  });

  group('PlayerGameInfo', () {
    test('round trips JSON shape', () {
      final playerGameInfo = PlayerGameInfo(
        playerId: "12",
        gameId: 'game-1',
        scores: [2, 3, 4],
        playOrderPosition: 1,
        place: '1st',
        totalScore: 9,
      );

      expect(playerGameInfo.toJson(), {
        'player_id': "12",
        'game_id': 'game-1',
        'scores': [2, 3, 4],
        'play_order_position': 1,
        'place': '1st',
        'total_score': 9,
        'strokes': 0,
        'score_timestamps': [],
      });

      final decoded = PlayerGameInfo.fromJson(playerGameInfo.toJson());

      expect(decoded.playerId, "12");
      expect(decoded.gameId, 'game-1');
      expect(decoded.scores, [2, 3, 4]);
      expect(decoded.playOrderPosition, 1);
      expect(decoded.place, '1st');
      expect(decoded.totalScore, 9);
    });
  });

  group('Game', () {
    test('initializes score maps for every player and hole', () {
      final game = _buildGame();

      expect(game.scores[game.players[0]], {1: 0, 2: 0, 3: 0});
      expect(game.scores[game.players[1]], {1: 0, 2: 0, 3: 0});
    });

    test('records scores and calculates totals', () {
      final game = _buildGame();
      final firstPlayer = game.players[0];

      game.recordScore(firstPlayer, 1, 2);
      game.recordScore(firstPlayer, 2, 3);
      game.recordScore(firstPlayer, 3, 4);

      expect(firstPlayer.scores, [2, 3, 4]);
      expect(firstPlayer.totalScore, 9);
      expect(game.calculateTotalScore(firstPlayer), 9);
    });

    test('round trips local JSON shape', () {
      final game = _buildGame();
      game.recordScore(game.players[0], 1, 2);

      final decoded = Game.fromJson(jsonEncode(game.toJson()));

      expect(decoded.id, 'game-1');
      expect(decoded.name, 'Friday League');
      expect(decoded.course.name, 'Putter Park');
      expect(decoded.players, hasLength(2));
      expect(decoded.players[0].scores, [2, 0, 0]);
      expect(decoded.status, 'unstarted_game');
    });
  });
}

Game _buildGame() {
  return Game(
    id: 'game-1',
    name: 'Friday League',
    course: Course(
      id: "7",
      name: 'Putter Park',
      numberOfHoles: 3,
      parStrokes: {1: 2, 2: 3, 3: 4},
    ),
    players: [
      PlayerGameInfo(playerId: "1", gameId: 'game-1', scores: []),
      PlayerGameInfo(playerId: "2", gameId: 'game-1', scores: []),
    ],
    scheduledTime: DateTime(2026, 5, 10, 12),
  );
}

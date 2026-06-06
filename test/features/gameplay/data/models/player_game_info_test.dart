import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/player_game_info.dart';

void main() {
  group('PlayerGameInfo constructor and defaults', () {
    test('creates with required fields and default values', () {
      final pgi = PlayerGameInfo(
        playerId: 'player-1',
        gameId: 'game-1',
        scores: [],
      );
      expect(pgi.playerId, 'player-1');
      expect(pgi.gameId, 'game-1');
      expect(pgi.scores, isEmpty);
      expect(pgi.playOrderPosition, 0);
      expect(pgi.place, '');
      expect(pgi.totalScore, 0);
      expect(pgi.strokes, 0);
      expect(pgi.scoreTimestamps, isEmpty);
    });

    test('creates with all fields provided', () {
      final pgi = PlayerGameInfo(
        playerId: 'p1',
        gameId: 'g1',
        scores: [3, 4, 5],
        playOrderPosition: 2,
        place: '2nd',
        totalScore: 12,
        strokes: 4,
        scoreTimestamps: ['2024-01-01T12:00:00.000Z'],
      );
      expect(pgi.scores, [3, 4, 5]);
      expect(pgi.playOrderPosition, 2);
      expect(pgi.place, '2nd');
      expect(pgi.totalScore, 12);
      expect(pgi.strokes, 4);
      expect(pgi.scoreTimestamps, ['2024-01-01T12:00:00.000Z']);
    });
  });

  group('PlayerGameInfo.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'player_id': 'p1',
        'game_id': 'g1',
        'scores': [2, 3, 4],
        'play_order_position': 1,
        'place': '1st',
        'total_score': 9,
        'strokes': 3,
        'score_timestamps': ['2024-01-01T12:00:00.000Z'],
      };
      final pgi = PlayerGameInfo.fromJson(json);
      expect(pgi.playerId, 'p1');
      expect(pgi.gameId, 'g1');
      expect(pgi.scores, [2, 3, 4]);
      expect(pgi.playOrderPosition, 1);
      expect(pgi.place, '1st');
      expect(pgi.totalScore, 9);
      expect(pgi.strokes, 3);
      expect(pgi.scoreTimestamps, ['2024-01-01T12:00:00.000Z']);
    });

    test('defaults strokes to 0 when not in json', () {
      final json = {
        'player_id': 'p2',
        'game_id': 'g2',
        'scores': [],
        'play_order_position': 0,
        'place': '',
        'total_score': 0,
      };
      final pgi = PlayerGameInfo.fromJson(json);
      expect(pgi.strokes, 0);
    });

    test('defaults scoreTimestamps to empty list when not in json', () {
      final json = {
        'player_id': 'p2',
        'game_id': 'g2',
        'scores': [],
        'play_order_position': 0,
        'place': '',
        'total_score': 0,
      };
      final pgi = PlayerGameInfo.fromJson(json);
      expect(pgi.scoreTimestamps, isEmpty);
    });
  });

  group('PlayerGameInfo.toJson', () {
    test('serializes all fields correctly', () {
      final pgi = PlayerGameInfo(
        playerId: 'p1',
        gameId: 'g1',
        scores: [2, 3],
        playOrderPosition: 1,
        place: '1st',
        totalScore: 5,
        strokes: 2,
        scoreTimestamps: ['t1'],
      );
      final json = pgi.toJson();
      expect(json['player_id'], 'p1');
      expect(json['game_id'], 'g1');
      expect(json['scores'], [2, 3]);
      expect(json['play_order_position'], 1);
      expect(json['place'], '1st');
      expect(json['total_score'], 5);
      expect(json['strokes'], 2);
      expect(json['score_timestamps'], ['t1']);
    });

    test('round-trip fromJson -> toJson preserves data', () {
      final original = {
        'player_id': 'abc',
        'game_id': 'xyz',
        'scores': [1, 2, 3],
        'play_order_position': 3,
        'place': '3rd',
        'total_score': 6,
        'strokes': 2,
        'score_timestamps': ['t1'],
      };
      final pgi = PlayerGameInfo.fromJson(original);
      final result = pgi.toJson();
      expect(result['player_id'], original['player_id']);
      expect(result['game_id'], original['game_id']);
      expect(result['scores'], original['scores']);
      expect(result['total_score'], original['total_score']);
      expect(result['strokes'], original['strokes']);
      expect(result['score_timestamps'], original['score_timestamps']);
    });
  });

  group('PlayerGameInfo mutability', () {
    test('scores list can be updated', () {
      final pgi = PlayerGameInfo(playerId: 'p', gameId: 'g', scores: []);
      pgi.scores = [3, 4, 5];
      expect(pgi.scores, [3, 4, 5]);
    });

    test('totalScore can be updated', () {
      final pgi = PlayerGameInfo(playerId: 'p', gameId: 'g', scores: []);
      pgi.totalScore = 42;
      expect(pgi.totalScore, 42);
    });

    test('place can be updated', () {
      final pgi = PlayerGameInfo(playerId: 'p', gameId: 'g', scores: []);
      pgi.place = '1st (tied)';
      expect(pgi.place, '1st (tied)');
    });

    test('scoreTimestamps list can be updated', () {
      final pgi = PlayerGameInfo(playerId: 'p', gameId: 'g', scores: []);
      pgi.scoreTimestamps = ['t1'];
      expect(pgi.scoreTimestamps, ['t1']);
    });
  });
}

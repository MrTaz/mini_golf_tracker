import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/course.dart';

void main() {
  group('Course constructor', () {
    test('creates with required fields', () {
      final course = Course(
        id: 'c1',
        name: 'Pine Valley',
        numberOfHoles: 18,
        parStrokes: {1: 3, 2: 4},
      );
      expect(course.id, 'c1');
      expect(course.name, 'Pine Valley');
      expect(course.numberOfHoles, 18);
      expect(course.parStrokes, {1: 3, 2: 4});
    });
  });

  group('Course.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'c1',
        'name': 'Test Course',
        'number_of_holes': 9,
        'par_strokes': {'1': 3, '2': 4, '3': 5},
      };
      final course = Course.fromJson(json);
      expect(course.id, 'c1');
      expect(course.name, 'Test Course');
      expect(course.numberOfHoles, 9);
      expect(course.parStrokes[1], 3);
      expect(course.parStrokes[2], 4);
      expect(course.parStrokes[3], 5);
    });

    test('defaults id to empty string when missing', () {
      final json = {
        'name': 'No ID Course',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      };
      final course = Course.fromJson(json);
      expect(course.id, '');
    });

    test('robustly parses non-standard and mixed types in json', () {
      final json = {
        'id': 'c_robust',
        'name': 'Robust Course',
        'number_of_holes': '18',
        'par_strokes': {
          '1': 3.0,
          '2': '4',
          '3': 5,
          '4.0': '3.0',
        },
      };
      final course = Course.fromJson(json);
      expect(course.numberOfHoles, 18);
      expect(course.parStrokes[1], 3);
      expect(course.parStrokes[2], 4);
      expect(course.parStrokes[3], 5);
      expect(course.parStrokes[4], 3);
    });
  });

  group('Course.fromMap', () {
    test('parses from camelCase map', () {
      final map = {
        'id': 'c2',
        'name': 'Map Course',
        'numberOfHoles': 18,
        'parStrokes': {'1': 3, '2': 4},
      };
      final course = Course.fromMap(map);
      expect(course.id, 'c2');
      expect(course.name, 'Map Course');
      expect(course.numberOfHoles, 18);
      expect(course.parStrokes[1], 3);
    });

    test('robustly parses from snake_case and non-standard types in map', () {
      final map = {
        'id': 'c3',
        'name': 'Snake Course',
        'number_of_holes': 9.0,
        'par_strokes': {
          '1': '3',
          '2.0': 4.0,
        },
      };
      final course = Course.fromMap(map);
      expect(course.id, 'c3');
      expect(course.name, 'Snake Course');
      expect(course.numberOfHoles, 9);
      expect(course.parStrokes[1], 3);
      expect(course.parStrokes[2], 4);
    });
  });

  group('Course.toJson', () {
    test('serializes correctly', () {
      final course = Course(
        id: 'c1',
        name: 'Valley Links',
        numberOfHoles: 18,
        parStrokes: {1: 3, 2: 4},
      );
      final json = course.toJson();
      expect(json['id'], 'c1');
      expect(json['name'], 'Valley Links');
      expect(json['number_of_holes'], 18);
      expect((json['par_strokes'] as Map)['1'], 3);
      expect((json['par_strokes'] as Map)['2'], 4);
    });

    test('round-trip fromJson -> toJson preserves data', () {
      final original = {
        'id': 'roundtrip',
        'name': 'RT Course',
        'number_of_holes': 9,
        'par_strokes': {'1': 3, '2': 4, '3': 5},
      };
      final course = Course.fromJson(original);
      final result = course.toJson();
      expect(result['id'], 'roundtrip');
      expect(result['name'], 'RT Course');
      expect(result['number_of_holes'], 9);
      expect((result['par_strokes'] as Map)['1'], 3);
    });
  });

  group('Course.getParValue', () {
    late Course course;
    setUp(() {
      course = Course(
        id: 'c',
        name: 'Par Course',
        numberOfHoles: 3,
        parStrokes: {1: 3, 2: 4, 3: 5},
      );
    });

    test('returns correct par for valid hole number', () {
      expect(course.getParValue(1), 3);
      expect(course.getParValue(2), 4);
      expect(course.getParValue(3), 5);
    });

    test('throws exception for invalid hole number', () {
      expect(() => course.getParValue(4), throwsException);
      expect(() => course.getParValue(0), throwsException);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/utilities.dart';

void main() {
  group('Utilities.getPositionSuffix', () {
    test('returns st for 1', () => expect(Utilities.getPositionSuffix(1), 'st'));
    test('returns nd for 2', () => expect(Utilities.getPositionSuffix(2), 'nd'));
    test('returns rd for 3', () => expect(Utilities.getPositionSuffix(3), 'rd'));
    test('returns th for 4', () => expect(Utilities.getPositionSuffix(4), 'th'));
    test('returns th for 11 (special case)', () => expect(Utilities.getPositionSuffix(11), 'th'));
    test('returns th for 12 (special case)', () => expect(Utilities.getPositionSuffix(12), 'th'));
    test('returns th for 13 (special case)', () => expect(Utilities.getPositionSuffix(13), 'th'));
    test('returns st for 21', () => expect(Utilities.getPositionSuffix(21), 'st'));
    test('returns nd for 22', () => expect(Utilities.getPositionSuffix(22), 'nd'));
    test('returns rd for 23', () => expect(Utilities.getPositionSuffix(23), 'rd'));
    test('returns th for 100', () => expect(Utilities.getPositionSuffix(100), 'th'));
    test('returns th for 111 (special case)', () => expect(Utilities.getPositionSuffix(111), 'th'));
    test('returns th for 112 (special case)', () => expect(Utilities.getPositionSuffix(112), 'th'));
    test('returns th for 113 (special case)', () => expect(Utilities.getPositionSuffix(113), 'th'));
    test('returns st for 101', () => expect(Utilities.getPositionSuffix(101), 'st'));
  });

  group('Utilities.getPositionString', () {
    test('formats 1 as 1st', () => expect(Utilities.getPositionString(1), '1st'));
    test('formats 2 as 2nd', () => expect(Utilities.getPositionString(2), '2nd'));
    test('formats 3 as 3rd', () => expect(Utilities.getPositionString(3), '3rd'));
    test('formats 4 as 4th', () => expect(Utilities.getPositionString(4), '4th'));
    test('formats 11 as 11th', () => expect(Utilities.getPositionString(11), '11th'));
    test('formats 21 as 21st', () => expect(Utilities.getPositionString(21), '21st'));
  });

  group('Utilities.debugPrintWithCallerInfo', () {
    test('does not throw on desktop platform', () {
      // On the VM test runner (non-mobile), this exercises the desktop branch
      expect(() => Utilities.debugPrintWithCallerInfo('test message'), returnsNormally);
    });
  });

  group('Utilities.isMobile', () {
    test('isMobile is a bool', () {
      expect(Utilities.isMobile, isA<bool>());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Utilities.getPositionSuffix', () {
    test(
        'returns st for 1', () => expect(Utilities.getPositionSuffix(1), 'st'));
    test(
        'returns nd for 2', () => expect(Utilities.getPositionSuffix(2), 'nd'));
    test(
        'returns rd for 3', () => expect(Utilities.getPositionSuffix(3), 'rd'));
    test(
        'returns th for 4', () => expect(Utilities.getPositionSuffix(4), 'th'));
    test('returns th for 11 (special case)',
        () => expect(Utilities.getPositionSuffix(11), 'th'));
    test('returns th for 12 (special case)',
        () => expect(Utilities.getPositionSuffix(12), 'th'));
    test('returns th for 13 (special case)',
        () => expect(Utilities.getPositionSuffix(13), 'th'));
    test('returns st for 21',
        () => expect(Utilities.getPositionSuffix(21), 'st'));
    test('returns nd for 22',
        () => expect(Utilities.getPositionSuffix(22), 'nd'));
    test('returns rd for 23',
        () => expect(Utilities.getPositionSuffix(23), 'rd'));
    test('returns th for 100',
        () => expect(Utilities.getPositionSuffix(100), 'th'));
    test('returns th for 111 (special case)',
        () => expect(Utilities.getPositionSuffix(111), 'th'));
    test('returns th for 112 (special case)',
        () => expect(Utilities.getPositionSuffix(112), 'th'));
    test('returns th for 113 (special case)',
        () => expect(Utilities.getPositionSuffix(113), 'th'));
    test('returns st for 101',
        () => expect(Utilities.getPositionSuffix(101), 'st'));
  });

  group('Utilities.getPositionString', () {
    test('formats 1 as 1st',
        () => expect(Utilities.getPositionString(1), '1st'));
    test('formats 2 as 2nd',
        () => expect(Utilities.getPositionString(2), '2nd'));
    test('formats 3 as 3rd',
        () => expect(Utilities.getPositionString(3), '3rd'));
    test('formats 4 as 4th',
        () => expect(Utilities.getPositionString(4), '4th'));
    test('formats 11 as 11th',
        () => expect(Utilities.getPositionString(11), '11th'));
    test('formats 21 as 21st',
        () => expect(Utilities.getPositionString(21), '21st'));
  });

  group('Utilities.debugPrintWithCallerInfo', () {
    test('works when isMobile is false', () {
      final originalIsMobile = Utilities.isMobile;
      Utilities.isMobile = false;
      try {
        expect(() => Utilities.debugPrintWithCallerInfo('test desktop message'),
            returnsNormally);
      } finally {
        Utilities.isMobile = originalIsMobile;
      }
    });

    test('works when isMobile is true', () {
      final originalIsMobile = Utilities.isMobile;
      Utilities.isMobile = true;
      try {
        expect(() => Utilities.debugPrintWithCallerInfo('test mobile message'),
            returnsNormally);
      } finally {
        Utilities.isMobile = originalIsMobile;
      }
    });

    test('notifies listeners when isMobile is false', () {
      final originalIsMobile = Utilities.isMobile;
      Utilities.isMobile = false;
      String? loggedMessage;
      void listener(String msg) {
        loggedMessage = msg;
      }

      Utilities.addLogListener(listener);
      try {
        Utilities.debugPrintWithCallerInfo('listener test desktop');
        expect(loggedMessage, contains('listener test desktop'));
      } finally {
        Utilities.removeLogListener(listener);
        Utilities.isMobile = originalIsMobile;
      }
    });

    test('notifies listeners when isMobile is true', () {
      final originalIsMobile = Utilities.isMobile;
      Utilities.isMobile = true;
      String? loggedMessage;
      void listener(String msg) {
        loggedMessage = msg;
      }

      Utilities.addLogListener(listener);
      try {
        Utilities.debugPrintWithCallerInfo('listener test mobile');
        expect(loggedMessage, equals('listener test mobile'));
      } finally {
        Utilities.removeLogListener(listener);
        Utilities.isMobile = originalIsMobile;
      }
    });
  });

  group('Utilities.backdropImageContinerWidget', () {
    test('returns a valid Container widget without throwing', () {
      expect(Utilities.backdropImageContinerWidget(), isNotNull);
    });
  });

  group('Utilities.formatStartTime', () {
    test('formats today correctly', () async {
      final today = DateTime.now();
      final result = await Utilities.formatStartTime(today);
      expect(result, contains('Today @'));
    });

    test('formats tomorrow correctly', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final result = await Utilities.formatStartTime(tomorrow);
      expect(result, contains('Tomorrow @'));
    });

    test('formats yesterday correctly', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = await Utilities.formatStartTime(yesterday);
      expect(result, contains('Yesterday @'));
    });

    test('formats 5 days ago correctly', () async {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final result = await Utilities.formatStartTime(past);
      expect(result, contains('5 day(s) ago @'));
    });

    test('formats far past date correctly', () async {
      // 40 days ago is > 30 days
      final farPast = DateTime.now().subtract(const Duration(days: 40));
      final result = await Utilities.formatStartTime(farPast);
      expect(result, isNot(contains('ago @')));
      expect(result, contains('@'));
    });

    test('appends US holiday name if date is a holiday', () async {
      // Christmas is Dec 25
      final christmas = DateTime(2026, 12, 25, 12, 0);
      final result = await Utilities.formatStartTime(christmas);
      expect(result, contains('Christmas Day'));
    });
  });

  group('Utilities.isMobile', () {
    test('isMobile is a bool', () {
      expect(Utilities.isMobile, isA<bool>());
    });
  });

  group('Utilities.isTestAccountBypass', () {
    test('returns false when not test email', () {
      expect(Utilities.isTestAccountBypass('other@example.com'), false);
    });
    test('returns true for test@example.com in debug mode', () {
      expect(Utilities.isTestAccountBypass('test@example.com'), true);
    });
  });
}

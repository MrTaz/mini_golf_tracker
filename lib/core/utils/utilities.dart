import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mini_golf_tracker/core/config/assets.dart';
import 'package:world_holidays/world_holidays.dart';

class Utilities {
  static bool isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static bool isTestAccountBypass(String? email) {
    return kDebugMode && email == 'test@example.com';
  }

  static Future<String> formatStartTime(DateTime startTime) async {
    final DateTime localDate = startTime.toLocal();
    final now = DateTime.now();
    final daysDifference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(localDate.year, localDate.month, localDate.day))
        .inDays;
    final timeFormatter = DateFormat.jm();
    String formattedResponse = "";
    if (daysDifference == -1) {
      formattedResponse = 'Tomorrow @ ${timeFormatter.format(localDate)}';
    } else if (daysDifference == 0) {
      formattedResponse = 'Today @ ${timeFormatter.format(localDate)}';
    } else if (daysDifference == 1) {
      formattedResponse = 'Yesterday @ ${timeFormatter.format(localDate)}';
    } else if (daysDifference <= 30 && daysDifference > 1) {
      formattedResponse =
          '$daysDifference day(s) ago @ ${timeFormatter.format(localDate)}';
    } else {
      final formatter = DateFormat.yMMMMd('en_US');
      formattedResponse =
          '${formatter.format(localDate)} @ ${timeFormatter.format(localDate)}';
    }

    final List<Holiday> holidays =
        await WorldHolidays().getHolidays('US', year: startTime.year);
    for (var holiday in holidays) {
      if (holiday.month == startTime.month && holiday.day == startTime.day) {
        return '$formattedResponse - ${holiday.name}';
      }
    }

    return formattedResponse;
  }

  static String getPositionSuffix(int position) {
    if (position % 10 == 1 && position % 100 != 11) {
      return "st";
    } else if (position % 10 == 2 && position % 100 != 12) {
      return "nd";
    } else if (position % 10 == 3 && position % 100 != 13) {
      return "rd";
    } else {
      return "th";
    }
  }

  static String getPositionString(int number) {
    return '$number${getPositionSuffix(number)}';
  }

  static Widget backdropImageContinerWidget() {
    return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            alignment: Alignment(1, 1),
            image: AppImages.backgroundLoggedIn,
          ),
        ));
  }

  static final List<void Function(String)> _logListeners = [];

  static void addLogListener(void Function(String) listener) {
    _logListeners.add(listener);
  }

  static void removeLogListener(void Function(String) listener) {
    _logListeners.remove(listener);
  }

  static void debugPrintWithCallerInfo(String message) {
    if (!Utilities.isMobile) {
      final stackTrace = StackTrace.current;
      final stackFrames = stackTrace.toString().split('\n');
      String fileNameToShow = 'unknown';
      String lineNumber = '0';
      String columnNumber = '0';

      final callerIndex = stackFrames.length <= 2 ? stackFrames.length - 1 : 2;
      if (callerIndex >= 0 && stackFrames.length > callerIndex) {
        final callerInfo = stackFrames[callerIndex].trim();
        final match = RegExp(r'\(([^)]+):(\d+):(\d+)\)').firstMatch(callerInfo);
        if (match != null) {
          final fullPath = match.group(1) ?? 'unknown';
          final fileName = fullPath.split('/').last;
          fileNameToShow = fileName.length > 35
              ? '${fileName.substring(0, 32)}...'
              : fileName;
          lineNumber = match.group(2) ?? '0';
          columnNumber = match.group(3) ?? '0';
        }
      }

      const maxFileNameLength = 35;
      final lineColumnPadding = maxFileNameLength - fileNameToShow.length;

      const lineColumnSeparator = ':';
      final formattedLineColumn =
          '$lineNumber$lineColumnSeparator$columnNumber';

      final tabsAfterFileName = '\t' *
          (lineColumnPadding ~/ 8 +
              1); // Calculate tabs based on 8-character tab width

      final timestamp = DateTime.now().toString();

      final modifiedCallerInfo =
          '[$timestamp] $fileNameToShow$tabsAfterFileName$formattedLineColumn\t $message';

      if (kDebugMode) {
        debugPrint(modifiedCallerInfo);
      }
      for (final listener in _logListeners) {
        listener(modifiedCallerInfo);
      }
    } else {
      if (kDebugMode) {
        debugPrint(message);
      }
      for (final listener in _logListeners) {
        listener(message);
      }
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mini_golf_tracker/assets.dart';

class Utilities {
  static bool isMobile =
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  static String formatStartTime(DateTime startTime) {
    final DateTime localDate = startTime.toLocal();
    final now = DateTime.now();
    final daysDifference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(localDate.year, localDate.month, localDate.day))
        .inDays;
    final timeFormatter = DateFormat.jm();
    // const String apiKey = '';
    // final CalendarificApi api = CalendarificApi(apiKey);
    // const String countryCode = "US";
    String formattedResponse = "";
    if (daysDifference == -1) {
      formattedResponse = 'Tomorrow @ ${timeFormatter.format(localDate)}';
    } else if (daysDifference == 0) {
      formattedResponse = 'Today @ ${timeFormatter.format(localDate)}';
    } else if (daysDifference == 1) {
      formattedResponse = 'Yesterday @ ${timeFormatter.format(localDate)}';
    } else if (daysDifference <= 30 && daysDifference > 1) {
      formattedResponse = '$daysDifference day(s) ago @ ${timeFormatter.format(localDate)}';
    } else {
      final formatter = DateFormat.yMMMMd('en_US');
      formattedResponse = '${formatter.format(localDate)} @ ${timeFormatter.format(localDate)}';
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

  //   Positioned(
  //   bottom: 0,
  //   right: 0,
  //   child: Container(
  //       width: MediaQuery.of(context).size.width,
  //       height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
  //       decoration: const BoxDecoration(
  //         image: DecorationImage(
  //           alignment: Alignment(1, 1),
  //           image: AppImage.backgroundLoggedIn,
  //         ),
  //       )),
  // ),
  static void debugPrintWithCallerInfo(String message) {
    if (!Utilities.isMobile) {
      final stackTrace = StackTrace.current;
      final stackFrames = stackTrace.toString().split('\n');
      final callerInfo = stackFrames[2].trim(); // Get the caller info from the third line of the stack trace
      final callerInfoParts = callerInfo.split(' ');

      final filePath =
          callerInfoParts[0].replaceFirst('packages/mini_golf_tracker/', ''); // Strip off the package prefix
      final lineColumn = callerInfoParts[1].split(':');
      final lineNumber = lineColumn[0];
      final columnNumber = lineColumn[1];

      final fileName = filePath.split('/').last;
      final fileNameToShow = fileName.length > 35 ? '${fileName.substring(0, 32)}...' : fileName;

      const maxFileNameLength = 35;
      final lineColumnPadding = maxFileNameLength - fileNameToShow.length;

      const lineColumnSeparator = ':';
      final formattedLineColumn = '$lineNumber$lineColumnSeparator$columnNumber';

      final tabsAfterFileName = '\t' * (lineColumnPadding ~/ 8 + 1); // Calculate tabs based on 8-character tab width

      final timestamp = DateTime.now().toString();

      final modifiedCallerInfo = '[$timestamp] $fileNameToShow$tabsAfterFileName$formattedLineColumn\t $message';

      (kDebugMode) ? debugPrint(modifiedCallerInfo) : null;
    } else {
      (kDebugMode) ? debugPrint(message) : null;
    }
  }
}

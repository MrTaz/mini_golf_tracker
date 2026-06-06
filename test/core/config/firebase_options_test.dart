import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/core/config/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('web options are correct', () {
      final web = DefaultFirebaseOptions.web;
      expect(web.apiKey, isNotNull);
    });

    test('android options are correct', () {
      final android = DefaultFirebaseOptions.android;
      expect(android.apiKey, isNotNull);
    });

    test('currentPlatform returns web on Web', () {
      isWebTest = true;
      expect(
          DefaultFirebaseOptions.currentPlatform, DefaultFirebaseOptions.web);
      isWebTest = false;
    });

    test('ios options are correct', () {
      final ios = DefaultFirebaseOptions.ios;
      expect(ios.apiKey, isNotNull);
    });

    test('currentPlatform returns android on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(DefaultFirebaseOptions.currentPlatform,
          DefaultFirebaseOptions.android);
      debugDefaultTargetPlatformOverride = null;
    });

    test('currentPlatform returns ios on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
          DefaultFirebaseOptions.currentPlatform, DefaultFirebaseOptions.ios);
      debugDefaultTargetPlatformOverride = null;
    });

    test('currentPlatform throws UnsupportedError on other platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
          () => DefaultFirebaseOptions.currentPlatform, throwsUnsupportedError);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

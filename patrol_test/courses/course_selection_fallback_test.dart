// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A Firestore stub that throws permission-denied on every collection access,
// simulating a scenario where the remote database is completely unreachable.
class ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(ThrowingFirestore());
    UserProvider().resetForTesting();
    MainScaffold.skipPrecacheForTesting = true;
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
  });

  patrolTest(
      'course selection can create a local course when remote courses are unavailable',
      ($) async {
    Course? selectedCourse;

    // Pump a host widget that pushes CoursesScreen via Navigator so we can
    // capture the popped result (the selected Course).
    await $.pumpWidgetAndSettle(MaterialApp(
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () async {
            selectedCourse = await Navigator.push<Course>(
              context,
              MaterialPageRoute(
                builder: (_) => const CoursesScreen(creatingGame: true),
              ),
            );
          },
          child: const Text('Open Courses'),
        );
      }),
    ));
    await $.pump(const Duration(milliseconds: 350));

    // 1. Open the CoursesScreen. Remote fetch fails silently → fallback UI.
    await $('Open Courses').tap();
    await $.pump(const Duration(milliseconds: 350));

    // 2. Verify graceful fallback: "No Courses Yet" appears and the
    //    "fairway_unreachable_card" error card does NOT appear.
    expect($('No Courses Yet'), findsOneWidget);
    expect($(find.byKey(const Key('fairway_unreachable_card'))), findsNothing);

    // 3. Add a new local course.
    await $('Add New Course').tap();
    await $.pump(const Duration(milliseconds: 350));

    await $('9 Holes').tap();
    await $.pump();

    await $(find.widgetWithText(TextField, 'Course Name'))
        .enterText('Local Integration Course');
    await $.pump();

    // Scroll "Create Course" into view and tap it.
    await $.tester.ensureVisible(find.text('Create Course'));
    await $.pump();
    await $('Create Course').tap();
    await $.pump(const Duration(milliseconds: 350));
    await $.pump(const Duration(milliseconds: 350));

    // 4. Verify the returned course object is correct.
    expect(selectedCourse, isNotNull);
    expect(selectedCourse!.name, 'Local Integration Course');

    // 5. Verify the course was persisted in SharedPreferences cache.
    final prefs = await SharedPreferences.getInstance();
    final cachedCourses = prefs.getStringList('courses') ?? [];
    expect(cachedCourses.single, contains('Local Integration Course'));
  });
}

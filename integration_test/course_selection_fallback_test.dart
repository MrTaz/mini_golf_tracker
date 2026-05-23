import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets(
      'course selection can create a local course when remote courses are unavailable',
      (tester) async {
    Course? selectedCourse;

    await tester.pumpWidget(MaterialApp(
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
    await pumpRoute(tester);

    await tester.tap(find.text('Open Courses'));
    await pumpRoute(tester);

    expect(find.text('No Courses Yet'), findsOneWidget);
    expect(find.byKey(const Key('fairway_unreachable_card')), findsNothing);

    await tester.tap(find.text('Add New Course'));
    await pumpRoute(tester);

    await tester.tap(find.text('9 Holes'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Course Name'),
      'Local Integration Course',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final createCourseButton = find.ancestor(
      of: find.text('Create Course'),
      matching: find.byType(ElevatedButton),
    );
    await tester.ensureVisible(createCourseButton);
    await tester.pump();
    await tester.tap(createCourseButton);
    await pumpRoute(tester);
    await pumpRoute(tester);

    expect(selectedCourse, isNotNull);
    expect(selectedCourse!.name, 'Local Integration Course');

    final prefs = await SharedPreferences.getInstance();
    final cachedCourses = prefs.getStringList('courses') ?? [];
    expect(cachedCourses.single, contains('Local Integration Course'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});
  });

  Widget createCoursesScreen(
      {bool creatingGame = false, Course? selectedCourse}) {
    return MaterialApp(
      home: CoursesScreen(
        creatingGame: creatingGame,
        selectedCourse: selectedCourse,
      ),
    );
  }

  testWidgets(
      'shows loading screen initially and then empty state if no courses exist',
      (tester) async {
    // 1. Build screen
    await tester.pumpWidget(createCoursesScreen());

    // 2. Initial state: should show loading indicator overlay
    expect(find.text('Preparing the Greens...'), findsOneWidget);
    expect(find.text('Fetching courses from the fairway...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // 3. Settle futures (fetch complete) with pump(duration) to avoid infinite animation timeout
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Finished loading: should show empty state
    expect(find.text('No Courses Yet'), findsOneWidget);
    expect(find.byIcon(Icons.sports_golf), findsOneWidget);
  });

  testWidgets('shows courses list when courses exist in database',
      (tester) async {
    // Populate fake Firestore
    await fakeFirestore.collection('courses').add({
      'name': 'Pebble Beach Mini',
      'number_of_holes': 18,
      'par_strokes': {'1': 3, '2': 3},
    });
    await fakeFirestore.collection('courses').add({
      'name': 'Augusta National Mini',
      'number_of_holes': 9,
      'par_strokes': {'1': 2},
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify course cards are shown
    expect(find.text('Pebble Beach Mini'), findsOneWidget);
    expect(find.text('Augusta National Mini'), findsOneWidget);
    expect(find.text('18 holes'), findsOneWidget);
    expect(find.text('9 holes'), findsOneWidget);
  });

  testWidgets('supports selecting a course in creatingGame mode',
      (tester) async {
    // Populate fake Firestore
    final docRef = await fakeFirestore.collection('courses').add({
      'name': 'Selectable Course',
      'number_of_holes': 18,
      'par_strokes': {'1': 3},
    });

    Course? returnedCourse;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                returnedCourse = await Navigator.push<Course>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CoursesScreen(creatingGame: true),
                  ),
                );
              },
              child: const Text('Go to Selection'),
            );
          },
        ),
      ),
    );

    // Tap button to go to CoursesScreen
    await tester.tap(find.text('Go to Selection'));
    await tester.pump(); // Start navigation transition
    await tester.pump(const Duration(
        milliseconds: 500)); // Finish transition and allow fetch to complete
    await tester.pump(); // Rebuild with fetched data

    // Verify selectable course exists
    expect(find.text('Selectable Course'), findsOneWidget);

    // Selectable courses have a check icon button when creatingGame is true
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Tap selection button
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(); // Start pop transition
    await tester
        .pump(const Duration(milliseconds: 500)); // Finish pop transition

    // Verify it popped back and returned the selected course
    expect(returnedCourse, isNotNull);
    expect(returnedCourse!.name, 'Selectable Course');
    expect(returnedCourse!.id, docRef.id);
  });

  testWidgets('triggers load more courses on scroll', (tester) async {
    // Add multiple courses to trigger pagination paging
    for (int i = 0; i < 8; i++) {
      await fakeFirestore.collection('courses').add({
        'name': 'Course $i',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
    }

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Scroll to bottom
    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);

    // Drag the scroll view to trigger the scroll listener
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('tapping add button shows create new course dialog',
      (tester) async {
    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Floating Action Button directly
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(); // Start dialog open transition
    await tester.pump(const Duration(milliseconds: 500)); // Finish transition

    // Verify Dialog or UI elements of Dialog are shown
    expect(find.text('Create New Course'), findsOneWidget);
  });

  testWidgets('tapping course item shows details dialog and allows deletion',
      (tester) async {
    // Populate fake Firestore with a course
    await fakeFirestore.collection('courses').add({
      'name': 'Pebble Beach Mini',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify course cards are shown and tap the course list item
    expect(find.text('Pebble Beach Mini'), findsOneWidget);
    await tester.tap(find.text('Pebble Beach Mini'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Details dialog is shown
    expect(find.text('Number of Holes: 9'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Delete button
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 500)); // Finish deletion & dialog dismissal

    // Verify dialog is closed and course is gone from database & UI
    expect(find.text('Number of Holes: 9'), findsNothing);
    expect(find.text('Pebble Beach Mini'), findsNothing);
  });

  testWidgets('tapping course item shows details dialog and allows editing',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Populate fake Firestore with a course
    await fakeFirestore.collection('courses').add({
      'name': 'Old Course Name',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the course list item
    await tester.tap(find.text('Old Course Name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Edit button
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester
        .pump(const Duration(milliseconds: 500)); // Open Edit Course dialog

    // Verify Edit dialog is shown
    expect(find.text('Edit Course'), findsOneWidget);

    // Change course name by typing in TextField
    await tester.enterText(
        find.widgetWithText(TextField, 'Course Name'), 'New Course Name');
    await tester.pump();

    // Tap Save button
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(
        const Duration(milliseconds: 500)); // Finish save and dialog dismissal

    // Verify dialog/screen is dismissed
    expect(find.text('Edit Course'), findsNothing);

    // Verify course is renamed in list
    expect(find.text('New Course Name'), findsOneWidget);
  });

  testWidgets('creating a new course via the dialog saves to database',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Floating Action Button directly
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Enter name
    await tester.enterText(
        find.widgetWithText(TextField, 'Course Name'), 'Fresh Course');
    await tester.pump();

    // Select 9 Holes card
    await tester.tap(find.text('9 Holes'));
    await tester.pump();

    // Tap Create button
    expect(find.text('Create Course'), findsOneWidget);
    await tester.tap(find.text('Create Course'));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 500)); // Finish create and dialog dismissal

    // Verify dialog/screen is dismissed
    expect(find.text('Create New Course'), findsNothing);

    // Verify new course is shown
    expect(find.text('Fresh Course'), findsOneWidget);
  });

  testWidgets(
      'attempting to save duplicate course shows duplicate error dialog',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Populate fake Firestore with an existing course
    await fakeFirestore.collection('courses').add({
      'name': 'Existing Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Floating Action Button directly
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Enter the same name
    await tester.enterText(
        find.widgetWithText(TextField, 'Course Name'), 'Existing Course');
    await tester.pump();

    // Select 9 Holes card
    await tester.tap(find.text('9 Holes'));
    await tester.pump();

    // Tap Create button
    await tester.tap(find.text('Create Course'));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds:
            500)); // Attemps to save, gets duplicate, shows error dialog

    // Verify Duplicate Course dialog is shown
    expect(find.text('Duplicate Course'), findsOneWidget);
    expect(
        find.text(
            'A course with the same name and number of holes already exists in the database.'),
        findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}

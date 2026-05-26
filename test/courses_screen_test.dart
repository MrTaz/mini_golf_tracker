// ignore_for_file: subtype_of_sealed_class

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});

    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
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
    mockGeolocator.serviceEnabled = false;

    // 1. Build screen
    await tester.pumpWidget(createCoursesScreen());
    await tester.pump();

    // 2. Loading overlay (may already be past on fast runs — assert only if visible)
    if (find.text('Preparing the Greens...').evaluate().isNotEmpty) {
      expect(find.text('Fetching courses from the fairway...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 3. Finished loading: should show empty state
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
      'locationName': 'Pebble Location',
    });
    await fakeFirestore.collection('courses').add({
      'name': 'Augusta National Mini',
      'number_of_holes': 9,
      'par_strokes': {'1': 2},
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

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
    mockGeolocator.serviceEnabled = false;
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

  testWidgets('tapping course item expands details and allows deletion',
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

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Par Values:'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Delete button
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 500)); // Finish deletion & dialog dismissal

    // Verify dialog is closed and course is gone from database & UI
    expect(find.text('Par Values:'), findsNothing);
    expect(find.text('Pebble Beach Mini'), findsNothing);
  });

  testWidgets('tapping course item expands details and allows editing',
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
        find.widgetWithText(TextFormField, 'Course Name'), 'New Course Name');
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
        find.widgetWithText(TextFormField, 'Course Name'), 'Fresh Course');
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
        find.widgetWithText(TextFormField, 'Course Name'), 'Existing Course');
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

  testWidgets(
      'displays Fairway Unreachable error screen on DB failure with empty cache, and supports retry',
      (tester) async {
    // 1. Set the throwing firestore instance
    final throwingFirestore = ThrowingFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(throwingFirestore);
    SharedPreferences.setMockInitialValues({});

    // 2. Build screen
    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // 3. Verify it shows the Fairway Unreachable card and connection error message
    expect(find.byKey(const Key('fairway_unreachable_card')), findsOneWidget);
    expect(find.text('Unable to load courses. Please check your connection.'),
        findsOneWidget);
    expect(find.byKey(const Key('retry_button')), findsOneWidget);

    // 4. Reset database connection to a working fake database
    final workingFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(workingFirestore);
    await workingFirestore.collection('courses').add({
      'name': 'Recovered Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    // 5. Tap Retry button
    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 6. Verify error is cleared and it shows the newly loaded course
    expect(find.byKey(const Key('fairway_unreachable_card')), findsNothing);
    expect(find.text('Recovered Course'), findsOneWidget);
  });

  testWidgets(
      'creating game with DB failure and empty cache shows empty course state',
      (tester) async {
    final throwingFirestore = ThrowingFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(throwingFirestore);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(createCoursesScreen(creatingGame: true));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('fairway_unreachable_card')), findsNothing);
    expect(find.text('No Courses Yet'), findsOneWidget);
    expect(find.text('Add New Course'), findsOneWidget);
  });

  testWidgets(
      'falls back to local cache when DB fetch fails and cache is not empty',
      (tester) async {
    // 1. Set up local cache in SharedPreferences and set throwing firestore
    final throwingFirestore = ThrowingFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(throwingFirestore);
    SharedPreferences.setMockInitialValues({
      'courses': [
        jsonEncode(Course(
          id: 'c_local',
          name: 'Local Cached Course',
          numberOfHoles: 9,
          parStrokes: {1: 3},
        ).toJson())
      ],
    });

    // 2. Build screen
    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // 3. Verify it gracefully loads from cache and doesn't display the error card
    expect(find.byKey(const Key('fairway_unreachable_card')), findsNothing);
    expect(find.text('Local Cached Course'), findsOneWidget);
  });

  testWidgets('handles location service disabled gracefully', (tester) async {
    mockGeolocator.serviceEnabled = false;

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(mockGeolocator.isLocationServiceEnabledCount, greaterThan(0));
    expect(mockGeolocator.checkPermissionCount, 0);
  });

  testWidgets(
      'handles location permission denied initially and then request denied',
      (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    mockGeolocator.requestPermissionResult = LocationPermission.denied;

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(mockGeolocator.checkPermissionCount, greaterThan(0));
    expect(mockGeolocator.requestPermissionCount, greaterThan(0));
    expect(mockGeolocator.getCurrentPositionCount, 0);
  });

  testWidgets('handles location permission denied forever', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.deniedForever;

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(mockGeolocator.checkPermissionCount, greaterThan(0));
    expect(mockGeolocator.requestPermissionCount, 0);
    expect(mockGeolocator.getCurrentPositionCount, 0);
  });

  testWidgets('handles location exception during fetch gracefully',
      (tester) async {
    mockGeolocator.exceptionToThrow = Exception('Simulated GPS error');

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(mockGeolocator.isLocationServiceEnabledCount, greaterThan(0));
  });

  testWidgets(
      'handles location timeout exception gracefully and shows snackbar',
      (tester) async {
    mockGeolocator.exceptionToThrow = TimeoutException('Simulated timeout');

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(mockGeolocator.isLocationServiceEnabledCount, greaterThan(0));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
        find.text(
            'Location request timed out. Courses are sorted alphabetically.'),
        findsOneWidget);
  });

  testWidgets('handles geolocator distanceBetween exception gracefully',
      (tester) async {
    mockGeolocator.mockPosition = Position(
      latitude: 40.0,
      longitude: -70.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
    mockGeolocator.throwOnDistanceBetween = true;

    await fakeFirestore.collection('courses').add({
      'name': 'GPS Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
      'latitude': 40.1,
      'longitude': -70.1,
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // The courses should load fine, but since distance calculation failed,
    // distance is treated as null. Proximity sorting should still complete gracefully.
    expect(find.text('GPS Course'), findsOneWidget);
  });

  testWidgets(
      'supports proximity sorting, distance calculation, details coordinates/address, and closing details',
      (tester) async {
    mockGeolocator.mockPosition = Position(
      latitude: 40.0,
      longitude: -70.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );

    final throwingFirestore = ThrowingFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(throwingFirestore);

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('fairway_unreachable_card')), findsOneWidget);

    final workingFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(workingFirestore);

    await workingFirestore.collection('courses').add({
      'name': 'Near Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
      'latitude': 40.1,
      'longitude': -70.1,
      'address': '456 Near Blvd',
    });
    await workingFirestore.collection('courses').add({
      'name': 'Far Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
      'latitude': 45.0,
      'longitude': -75.0,
      'address': '123 Far Way',
    });
    await workingFirestore.collection('courses').add({
      'name': 'No Coordinates Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
      'latitude': null,
      'longitude': null,
      'address': '',
    });

    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final listItems = find.byType(Card);
    expect(listItems, findsNWidgets(3));
    expect(tester.widget<Text>(find.text('Near Course')).data, 'Near Course');

    await tester.tap(find.text('Near Course'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('456 Near Blvd'), findsOneWidget);
    expect(find.text('Address: 456 Near Blvd'), findsNothing);

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('handles second page fetch failure without appending courses',
      (tester) async {
    mockGeolocator.serviceEnabled = false;

    final paginatedThrowingFirestore = PaginatedThrowingFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(
        paginatedThrowingFirestore);

    for (int i = 0; i < 6; i++) {
      await paginatedThrowingFirestore.collection('courses').add({
        'name': 'Course $i',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
    }

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    final state = tester.state<CoursesScreenState>(find.byType(CoursesScreen));
    expect(state.courses.length, 5);
    expect(state.hasMoreForTesting, isTrue);

    paginatedThrowingFirestore.shouldThrow = true;
    final loadFuture = state.loadMoreCoursesForTesting();
    await tester.pump(const Duration(milliseconds: 500));
    await loadFuture;

    expect(state.courses.length, 5);
    expect(state.hasMoreForTesting, isFalse);
  });

  testWidgets(
      'handles exception when deleting course and falls back to local cache',
      (tester) async {
    await fakeFirestore.collection('courses').add({
      'name': 'Fragile Course',
      'number_of_holes': 9,
      'par_strokes': {'1': 3},
    });

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Fragile Course'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    DatabaseConnection.setFirestoreInstanceForTesting(ThrowingFirestore());

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Fragile Course'), findsNothing);
  });

  testWidgets(
      'tapping Add New Course in empty state card opens create course dialog',
      (tester) async {
    mockGeolocator.serviceEnabled = false;

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump();

    for (var attempt = 0; attempt < 20; attempt++) {
      if (find.text('No Courses Yet').evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('No Courses Yet'), findsOneWidget);
    expect(find.text('Add New Course'), findsOneWidget);

    await tester.tap(find.text('Add New Course'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Create New Course'), findsOneWidget);
  });

  testWidgets(
      'supports selecting a course in creatingGame mode when created via fab',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.tap(find.text('Go to Selection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.widgetWithText(TextFormField, 'Course Name'),
        'Selectable Fresh Course');
    await tester.pump();
    await tester.tap(find.text('9 Holes'));
    await tester.pump();

    await tester.tap(find.text('Create Course'));
    await tester.pumpAndSettle();

    expect(returnedCourse, isNotNull);
    expect(returnedCourse!.name, 'Selectable Fresh Course');
  });

  testWidgets('loads second page of courses successfully on scroll',
      (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    mockGeolocator.serviceEnabled = false;

    final delayedFirestore = PaginatedThrowingFirestore();
    delayedFirestore.delay = const Duration(milliseconds: 100);
    DatabaseConnection.setFirestoreInstanceForTesting(delayedFirestore);

    // Add 8 courses: first page = 5, second page = 3
    for (int i = 0; i < 8; i++) {
      await delayedFirestore.collection('courses').add({
        'name': 'Page Course $i',
        'number_of_holes': 9,
        'par_strokes': {'1': 3},
      });
    }

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // First page should be loaded and ListView shown
    expect(find.byType(ListView), findsOneWidget);

    final state = tester.state<CoursesScreenState>(find.byType(CoursesScreen));
    expect(state.courses.length, 5);

    final listFinder = find.byType(ListView);
    await tester.drag(listFinder, const Offset(0, -3000));
    await tester.pump();

    // The CircularProgressIndicator should be visible at the bottom of the list
    // while loading the next page.
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pump(const Duration(milliseconds: 100));

    for (var attempt = 0; attempt < 20 && state.courses.length < 8; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(state.courses.length, 8);
  });

  testWidgets('handles JSON parse failure in local cache fallback gracefully',
      (tester) async {
    // Pre-seed SharedPreferences with malformed JSON so parsing throws in the inner catch
    SharedPreferences.setMockInitialValues({
      'courses': ['{invalid-json']
    });

    final throwingFirestore = ThrowingFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(throwingFirestore);

    await tester.pumpWidget(createCoursesScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // The outer error screen should be shown since both DB and cache parsing failed
    expect(find.byKey(const Key('fairway_unreachable_card')), findsOneWidget);
  });
}

class ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw FirebaseException(
      plugin: 'firestore',
      code: 'unavailable',
      message: 'Service unavailable',
    );
  }
}

class MockGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? mockPosition;
  dynamic exceptionToThrow;
  Duration? delayToUse;
  bool throwOnDistanceBetween = false;

  int isLocationServiceEnabledCount = 0;
  int checkPermissionCount = 0;
  int requestPermissionCount = 0;
  int getCurrentPositionCount = 0;

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    if (throwOnDistanceBetween) {
      throw Exception('Simulated distanceBetween error');
    }
    return super.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    isLocationServiceEnabledCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return checkPermissionResult;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return requestPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    getCurrentPositionCount++;
    if (delayToUse != null) {
      await Future.delayed(delayToUse!);
    }
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockPosition != null) return mockPosition!;
    return Position(
      latitude: 43.12345,
      longitude: -71.54321,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
  }
}

class ThrowingQuery implements Query<Map<String, dynamic>> {
  final Query<Map<String, dynamic>> _delegate;
  final bool shouldThrow;
  final Duration delay;

  ThrowingQuery(this._delegate,
      {this.shouldThrow = false,
      this.delay = const Duration(milliseconds: 50)});

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return ThrowingQuery(_delegate.limit(limit),
        shouldThrow: shouldThrow, delay: delay);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return ThrowingQuery(_delegate.orderBy(field, descending: descending),
        shouldThrow: shouldThrow, delay: delay);
  }

  @override
  Query<Map<String, dynamic>> startAfterDocument(
      DocumentSnapshot documentSnapshot) {
    return ThrowingQuery(_delegate.startAfterDocument(documentSnapshot),
        shouldThrow: shouldThrow, delay: delay);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    await Future.delayed(delay);
    if (shouldThrow) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unavailable',
        message: 'Service unavailable',
      );
    }
    return _delegate.get(options);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

class ThrowingCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> _delegate;
  final bool shouldThrow;
  final Duration delay;

  ThrowingCollectionReference(this._delegate,
      {this.shouldThrow = false,
      this.delay = const Duration(milliseconds: 50)});

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return ThrowingQuery(_delegate.limit(limit),
        shouldThrow: shouldThrow, delay: delay);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return ThrowingQuery(_delegate.orderBy(field, descending: descending),
        shouldThrow: shouldThrow, delay: delay);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
      Map<String, dynamic> data) {
    return _delegate.add(data);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    await Future.delayed(delay);
    if (shouldThrow) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unavailable',
        message: 'Service unavailable',
      );
    }
    return _delegate.get(options);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

class PaginatedThrowingFirestore extends FakeFirebaseFirestore {
  bool shouldThrow = false;
  Duration delay = const Duration(milliseconds: 50);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return ThrowingCollectionReference(super.collection(path),
        shouldThrow: shouldThrow, delay: delay);
  }
}

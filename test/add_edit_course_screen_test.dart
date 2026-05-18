import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/add_edit_course_screen.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/map_picker_screen.dart';

// --- MOCK GEOLOCATOR PLATFORM ---
class MockGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? mockPosition;
  String? exceptionToThrow;
  Duration? delayToUse;

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return checkPermissionResult;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return requestPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
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

// --- MOCK GEOCODING PLATFORM ---
class MockGeocodingPlatform extends GeocodingPlatform {
  List<geocoding.Location> locationsResult = [];
  List<geocoding.Placemark> placemarksResult = [];
  String? exceptionToThrow;

  @override
  Future<List<geocoding.Location>> locationFromAddress(
    String address, {
    String? localeIdentifier,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return locationsResult.isNotEmpty
        ? locationsResult
        : [
            geocoding.Location(
              latitude: 43.12345,
              longitude: -71.54321,
              timestamp: DateTime.now(),
            )
          ];
  }

  @override
  Future<List<geocoding.Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    String? localeIdentifier,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return placemarksResult.isNotEmpty
        ? placemarksResult
        : [
            const geocoding.Placemark(
              name: 'Chucksters',
              street: '53 Carter Hill Rd',
              locality: 'Hooksett',
              administrativeArea: 'NH',
              postalCode: '03106',
              country: 'United States',
            )
          ];
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockGeolocatorPlatform mockGeolocator;
  late MockGeocodingPlatform mockGeocoding;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});

    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;

    mockGeocoding = MockGeocodingPlatform();
    GeocodingPlatform.instance = mockGeocoding;
  });

  Widget createScreen({Course? course}) {
    return MaterialApp(
      home: AddEditCourseScreen(course: course),
    );
  }

  testWidgets('renders all course creation fields successfully',
      (tester) async {
    await tester.pumpWidget(createScreen());

    expect(find.text('Create New Course'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Course Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Address (Optional)'),
        findsOneWidget);
    expect(find.text('Fairway Par Configuration'), findsOneWidget);
    expect(find.text('18 Holes'), findsOneWidget);
    expect(find.text('9 Holes'), findsOneWidget);
    expect(find.text('Create Course'), findsOneWidget);
  });

  testWidgets('renders initial editing values when a course is supplied',
      (tester) async {
    final course = Course(
      id: 'course-1',
      name: 'Chucksters Case Course',
      numberOfHoles: 9,
      parStrokes: {1: 3, 2: 2, 3: 4},
      address: '53 Carter Hill Rd, Hooksett, NH',
      latitude: 43.111,
      longitude: -71.222,
    );

    await tester.pumpWidget(createScreen(course: course));

    expect(find.text('Edit Course'), findsOneWidget);
    expect(find.text('Chucksters Case Course'), findsOneWidget);
    expect(find.text('53 Carter Hill Rd, Hooksett, NH'), findsOneWidget);
    expect(find.text('Coordinates: 43.11100, -71.22200'), findsOneWidget);

    // Default par configuration for hole 2 is 2
    expect(find.text('Hole 2'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Par stroke text for hole 2
  });

  testWidgets(
      'fetches GPS location and automatically populates reverse geocoded address',
      (tester) async {
    await tester.pumpWidget(createScreen());

    // Clicks "Use Current Location" icon button
    final locationBtn = find.byIcon(Icons.my_location);
    expect(locationBtn, findsOneWidget);

    await tester.tap(locationBtn);
    await tester.pump(); // Starts locating loader
    await tester.pump(const Duration(
        milliseconds: 500)); // Finish locate and geocoding Futures

    // Resolved address should be set automatically
    expect(find.text('53 Carter Hill Rd, Hooksett, NH, 03106'), findsOneWidget);
    expect(find.text('Coordinates: 43.12345, -71.54321'), findsOneWidget);
  });

  testWidgets('displays error inline when GPS fetching fails', (tester) async {
    mockGeolocator.exceptionToThrow = 'GPS device timeout';

    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('GPS device timeout'), findsOneWidget);

    // Closes error banner
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('GPS device timeout'), findsNothing);
  });

  testWidgets('select on map works immediately if permission is granted',
      (tester) async {
    await tester.pumpWidget(createScreen());

    final mapBtn = find.byIcon(Icons.map_outlined);
    expect(mapBtn, findsOneWidget);

    await tester.tap(mapBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify it pushed MapPickerScreen
    expect(find.byType(MapPickerScreen), findsOneWidget);
  });

  testWidgets(
      'falls back to Address Capture bottom sheet when location permission is denied, and handles enable maps',
      (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;

    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Address bottom sheet is shown
    expect(find.text('Location Access Required'), findsOneWidget);
    expect(find.text('Use Map (Grant Permission)'), findsOneWidget);

    // Clicks "Use Map (Grant Permission)" which changes mock result
    mockGeolocator.requestPermissionResult = LocationPermission.whileInUse;
    await tester.tap(find.text('Use Map (Grant Permission)'));
    await tester.pump();
    await tester.pump(const Duration(
        milliseconds: 500)); // Pops sheet and navigates to MapPicker

    expect(find.byType(MapPickerScreen), findsOneWidget);
  });

  testWidgets(
      'address capture sheet structured form input works and geocodes coordinates in background',
      (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;

    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Type address details
    await tester.enterText(
        find.widgetWithText(TextField, 'Street Address'), '100 Main St');
    await tester.enterText(find.widgetWithText(TextField, 'City'), 'Hooksett');
    await tester.enterText(find.widgetWithText(TextField, 'State'), 'NH');
    await tester.enterText(find.widgetWithText(TextField, 'ZIP Code'), '03106');
    await tester.pump();

    // Confirm Address
    await tester.tap(find.text('Confirm Address'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // geocoding resolve

    // Check main form has address and coordinates banner
    expect(find.text('100 Main St, Hooksett, NH, 03106'), findsOneWidget);
    expect(find.text('Coordinates: 43.12345, -71.54321'), findsOneWidget);
  });

  testWidgets(
      'handles conflict warning choices correctly when duplicates exist',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Insert an existing course in database
    await fakeFirestore.collection('courses').add({
      'name': 'Chucksters Fire Tower',
      'number_of_holes': 18,
      'latitude': 43.12345,
      'longitude': -71.54321,
      'address': '53 Carter Hill Rd, Hooksett, NH',
      'par_strokes': {'1': 3},
    });

    // Create adding screen
    await tester.pumpWidget(createScreen());

    // Select 18 holes
    await tester.tap(find.text('18 Holes'));
    await tester.pump();

    // Enter details for duplicate
    await tester.enterText(find.widgetWithText(TextField, 'Course Name'),
        'Chucksters Case Course');
    // Fetch GPS to trigger duplicate coordinate matching
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Save Course
    await tester.tap(find.text('Create Course'));
    await tester.pump();
    await tester.pump(
        const Duration(milliseconds: 500)); // triggers conflict alert dialog

    // Dialog showing conflicting course
    expect(find.text('Nearby Courses Found'), findsOneWidget);
    expect(find.text('Chucksters Fire Tower'), findsOneWidget);
    expect(find.text('Add Second Course Anyway'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Let's test "Cancel" choice first
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Nearby Courses Found'),
        findsNothing); // Dialog dismissed, still on AddEditCourseScreen

    // Save again to trigger dialog
    await tester.tap(find.text('Create Course'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap "Add Second Course Anyway"
    await tester.tap(find.text('Add Second Course Anyway'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify it saved and popped back
    final savedCourses = await fakeFirestore.collection('courses').get();
    expect(savedCourses.docs.length, 2);
    expect(savedCourses.docs.last.get('name'), 'Chucksters Case Course');
  });

  testWidgets('increments and decrements par strokes', (tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createScreen());

    // Select 18 holes
    await tester.tap(find.text('18 Holes'));
    await tester.pump();

    // Hole 1 stepper: find add/remove icons
    final plusFinder = find.byIcon(Icons.add).first;
    final minusFinder = find.byIcon(Icons.remove).first;

    // Verify default value is 3
    expect(find.text('3'), findsNWidgets(18)); // All 18 holes default to 3

    // Tap plus
    await tester.tap(plusFinder);
    await tester.pump();
    expect(find.text('4'), findsOneWidget);

    // Tap minus twice
    await tester.tap(minusFinder);
    await tester.pump();
    await tester.tap(minusFinder);
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('fails to check permissions when Geolocator throws error',
      (tester) async {
    mockGeolocator.exceptionToThrow = 'Simulated geolocator error';
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Location Access Required'), findsOneWidget);
  });

  testWidgets('map selection returns coordinates and address', (tester) async {
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    Navigator.of(tester.element(find.byType(MapPickerScreen))).pop({
      'latitude': 42.123,
      'longitude': -71.123,
      'address': 'Test Address from Map',
    });
    await tester.pumpAndSettle();

    expect(find.text('Test Address from Map'), findsOneWidget);
    expect(find.text('Coordinates: 42.12300, -71.12300'), findsOneWidget);
  });

  testWidgets('grant permission fails from bottom sheet', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    mockGeolocator.exceptionToThrow = 'Simulated request error';
    await tester.tap(find.text('Use Map (Grant Permission)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
        find.textContaining('Could not request permissions:'), findsOneWidget);
  });

  testWidgets('grant permission denied from bottom sheet', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    mockGeolocator.requestPermissionResult = LocationPermission.denied;
    await tester.tap(find.text('Use Map (Grant Permission)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Location permission denied. Please use the form below.'),
        findsOneWidget);
  });

  testWidgets('Geocoding of user-captured address fails', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Street Address'), '100 Main St');
    await tester.pump();

    mockGeocoding.exceptionToThrow = 'Geocoding network error';
    await tester.tap(find.text('Confirm Address'));
    await tester.pump(); // start async operation
    await tester.pumpAndSettle(); // render the error snackbar

    expect(
        find.textContaining(
            'Map coordinates could not be resolved automatically'),
        findsOneWidget);
  });

  testWidgets('Save course without holes selected', (tester) async {
    await tester.pumpWidget(createScreen());

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Course Name'), 'New Course');
    // Do not tap 9 or 18 holes

    final createCourseBtn = find.text('Create Course');
    await tester.ensureVisible(createCourseBtn);
    await tester.tap(createCourseBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please select the number of holes.'), findsOneWidget);
  });

  testWidgets('Clear coordinate button tapped', (tester) async {
    final course = Course(
      id: 'course-1',
      name: 'Chucksters',
      numberOfHoles: 9,
      parStrokes: {1: 3},
      latitude: 43.111,
      longitude: -71.222,
    );
    await tester.pumpWidget(createScreen(course: course));

    await tester.tap(find.byIcon(Icons.cancel_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Coordinates:'), findsNothing);
  });

  testWidgets('Empty address coordinates geocode on save', (tester) async {
    await tester.pumpWidget(createScreen());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Course Name'), 'New Course');
    await tester.tap(find.text('18 Holes'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (Optional)'),
        '53 Carter Hill Rd');

    final createCourseBtn = find.text('Create Course');
    await tester.ensureVisible(createCourseBtn);
    await tester.tap(createCourseBtn);
    await tester.pumpAndSettle();

    // It should have geocoded and saved. The screen closes on success.
    expect(find.byType(AddEditCourseScreen), findsNothing);
  });

  testWidgets('Close permission denied sheet', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'The interactive map needs location permissions. You can grant permission to use the map, or fill out this quick address form instead.'),
        findsNothing);
  });

  testWidgets('Address capture sheet validation fails on empty street',
      (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Address'));
    await tester.pumpAndSettle();

    expect(find.text('Street address is required to locate the course.'),
        findsOneWidget);
  });

  testWidgets('Grant permission after initial denial succeeds', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    await tester.pumpWidget(createScreen());
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    mockGeolocator.requestPermissionResult = LocationPermission.whileInUse;
    await tester.tap(find.text('Use Map (Grant Permission)'));
    await tester.pumpAndSettle();

    expect(find.byType(MapPickerScreen), findsOneWidget);
  });

  testWidgets('Reverse geocoding fails after fetching GPS location via icon',
      (tester) async {
    await tester.pumpWidget(createScreen());

    mockGeocoding.placemarksResult = [];
    mockGeocoding.exceptionToThrow = 'Simulated geocoding error';

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not get coordinates automatically'),
        findsNothing); // It just silently fails reverse geocoding but gets coordinates
  });

  testWidgets('Exact address match in conflict check', (tester) async {
    await fakeFirestore.collection('courses').add({
      'name': 'Exact Course',
      'numberOfHoles': 18,
      'parStrokes': {'1': 3},
      'address': '123 Exact St',
    });

    await tester.pumpWidget(createScreen());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Course Name'), 'Exact Course');
    await tester.tap(find.text('18 Holes'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (Optional)'),
        '123 Exact St');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final createCourseBtn = find.text('Create Course');
    await tester.scrollUntilVisible(createCourseBtn, 100.0,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(createCourseBtn);
    await tester.pumpAndSettle();

    expect(find.text('Nearby Courses Found'), findsOneWidget);
  });

  // testWidgets('Database error during conflict check', (tester) async {
  //   // Skipped since FakeFirebaseFirestore doesn't natively support throwing exceptions here easily
  // });

  testWidgets('Select existing course in duplicate dialog', (tester) async {
    await fakeFirestore.collection('courses').add({
      'name': 'Exact Course',
      'numberOfHoles': 18,
      'parStrokes': {'1': 3},
      'address': '123 Exact St',
    });

    await tester.pumpWidget(createScreen());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Course Name'), 'Exact Course');
    await tester.tap(find.text('18 Holes'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (Optional)'),
        '123 Exact St');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final createCourseBtn = find.text('Create Course');
    await tester.scrollUntilVisible(createCourseBtn, 100.0,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(createCourseBtn);
    await tester.pumpAndSettle();

    // Tap the conflicting course card to use it
    await tester.tap(find.text('Exact Course').last);
    await tester.pumpAndSettle();

    // Should close the screen
    expect(find.byType(AddEditCourseScreen), findsNothing);
  });

  testWidgets('Geocoding fails on final save', (tester) async {
    await tester.pumpWidget(createScreen());
    await tester.enterText(find.widgetWithText(TextFormField, 'Course Name'),
        'Geocode Fail Course');
    await tester.tap(find.text('18 Holes'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (Optional)'),
        'Some Valid Address');

    mockGeocoding.exceptionToThrow = 'Final Geocoding Error';

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final createCourseBtn = find.text('Create Course');
    await tester.scrollUntilVisible(createCourseBtn, 100.0,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(createCourseBtn);
    await tester.pumpAndSettle();

    // Geocoding fails silently, saves anyway
    expect(find.byType(AddEditCourseScreen), findsNothing);
  });

  testWidgets('GPS loading state indicator shows in suffix', (tester) async {
    mockGeolocator.delayToUse = const Duration(seconds: 1);
    await tester.pumpWidget(createScreen());

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();
  });
}

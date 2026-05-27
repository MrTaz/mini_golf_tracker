import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_golf_tracker/add_edit_course_screen.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/map_picker_screen.dart';

// --- MOCK GEOLOCATOR PLATFORM ---
class MockGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
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
  @override
  Future<List<geocoding.Location>> locationFromAddress(
    String address, {
    String? localeIdentifier,
  }) async {
    return [
      geocoding.Location(
        latitude: 43.11111,
        longitude: -71.22222,
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
    return [
      geocoding.Placemark(
        name: 'Test Business Name',
        street: '123 Fake St',
        locality: 'Testville',
        administrativeArea: 'TS',
        postalCode: '12345',
        country: 'TestCountry',
      )
    ];
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    GeocodingPlatform.instance = MockGeocodingPlatform();
    MapPickerScreen.searchClientForTesting = MockClient((request) async {
      return http.Response('''
[
  {
    "display_name": "Test Business Name, 123 Fake St, Testville, TS, 12345",
    "name": "Test Business Name",
    "lat": "43.11111",
    "lon": "-71.22222",
    "address": {
      "house_number": "123",
      "road": "Fake St",
      "city": "Testville",
      "state": "TS",
      "postcode": "12345"
    }
  }
]
''', 200);
    });
  });

  tearDown(() {
    MapPickerScreen.searchClientForTesting = null;
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: CoursesScreen(),
    );
  }

  testWidgets('Course creation flow with map picker and location name',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditCourseScreen), findsOneWidget);

    // 1. Enter course name and holes
    await tester.enterText(
        find.byType(TextFormField).first, 'Test Integration Course');
    await tester.enterText(find.byType(TextFormField).at(1), '18');
    await tester.pump();

    // Tap out to trigger par grid creation
    await tester.tap(find
        .byType(ElevatedButton)
        .first); // Tapping a random button to dismiss keyboard
    await tester.pumpAndSettle();

    // 2. Open Map Picker
    final openMapButton = find.byTooltip('Select on Map');
    await tester.ensureVisible(openMapButton);
    await tester.tap(openMapButton);
    await tester.pumpAndSettle();

    // 3. We are now in MapPickerScreen. Search for an address.
    expect(find.byType(MapPickerScreen), findsOneWidget);

    // Wait for initial location load (simulate map settling)
    await tester.pump(const Duration(seconds: 1));

    // Type in search bar
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, '123 Fake St');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Business Name'));
    await tester.pumpAndSettle();

    // Tap Select Location button
    final selectLocationButton = find.text('Confirm Location');
    expect(selectLocationButton, findsOneWidget);
    await tester.tap(selectLocationButton);
    await tester.pumpAndSettle();

    // 4. Back in AddEditCourseScreen, verify location name and address are set
    expect(find.byType(AddEditCourseScreen), findsOneWidget);

    expect(find.text('Test Business Name'), findsOneWidget);
    expect(find.text('123 Fake St, Testville, TS, 12345'), findsOneWidget);

    // Verify raw coordinates are NOT displayed
    expect(find.textContaining('Lat: 43.11111'), findsNothing);

    // 5. Submit Course
    // Course name and par values are already initialized correctly.
    // We need to select the number of holes.
    final holesButton = find.text('18 Holes');
    await tester.ensureVisible(holesButton);
    await tester.tap(holesButton);
    await tester.pumpAndSettle();

    final saveButton = find.text('Create Course');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Should navigate back to CoursesScreen.
    expect(find.byType(AddEditCourseScreen), findsNothing);
    expect(find.byType(CoursesScreen), findsOneWidget);

    final createdCourse = find.text('Test Integration Course');
    expect(createdCourse, findsOneWidget);
    await tester.tap(createdCourse);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Test Business Name'), findsOneWidget);
    expect(find.text('Total Par: 54'), findsOneWidget);
  });
}

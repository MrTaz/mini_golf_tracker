// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:io';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_golf_tracker/features/courses/presentation/screens/add_edit_course_screen.dart';
import 'package:mini_golf_tracker/features/courses/presentation/screens/courses_screen.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_golf_tracker/features/courses/presentation/screens/map_picker_screen.dart';

// --- MOCK HTTP OVERRIDES FOR IMAGE LOADING ---
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(MockHttpClientResponse());
    }
    if (invocation.memberName == #addStream) {
      return Future.value();
    }
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  String get reasonPhrase => '';

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([
      [
        71,
        73,
        70,
        56,
        57,
        97,
        1,
        0,
        1,
        0,
        128,
        0,
        0,
        0,
        0,
        0,
        255,
        255,
        255,
        33,
        249,
        4,
        1,
        0,
        0,
        0,
        0,
        44,
        0,
        0,
        0,
        0,
        1,
        0,
        1,
        0,
        0,
        2,
        2,
        76,
        1,
        0,
        59
      ]
    ]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

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
  setUp(() {
    HttpOverrides.global = MockHttpOverrides();
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
    HttpOverrides.global = null;
    MapPickerScreen.searchClientForTesting = null;
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: CoursesScreen(),
    );
  }

  patrolTest('Course creation flow with map picker and location name',
      ($) async {
    await $.pumpWidgetAndSettle(createWidgetUnderTest());

    await $(FloatingActionButton).tap();
    await $.pumpAndSettle();
    expect($(AddEditCourseScreen), findsOneWidget);

    // 1. Enter course name and holes
    await $(TextFormField).at(0).enterText('Test Integration Course');
    await $(TextFormField).at(1).enterText('18');
    await $.pump();

    // Tap out to trigger par grid creation
    await $(ElevatedButton).at(0).tap();
    await $.pumpAndSettle();

    // 2. Open Map Picker
    final openMapButton = find.byTooltip('Select on Map');
    await $.tester.ensureVisible(openMapButton);
    await $(openMapButton).tap();
    await $.pumpAndSettle();

    // 3. We are now in MapPickerScreen. Search for an address.
    expect($(MapPickerScreen), findsOneWidget);

    // Wait for initial location load (simulate map settling)
    await $.pump(const Duration(seconds: 1));

    // Type in search bar
    final searchField = $(TextField);
    expect(searchField, findsOneWidget);
    await searchField.enterText('123 Fake St');
    final TextField textField = $.tester.widget(find.byType(TextField));
    textField.onSubmitted!('123 Fake St');
    await $.pumpAndSettle();

    await $('Test Business Name').tap();
    await $.pumpAndSettle();

    // Tap Select Location button
    final selectLocationButton = $('Confirm Location');
    expect(selectLocationButton, findsOneWidget);
    await selectLocationButton.tap();
    await $.pumpAndSettle();

    // 4. Back in AddEditCourseScreen, verify location name and address are set
    expect($(AddEditCourseScreen), findsOneWidget);

    expect($('Test Business Name'), findsOneWidget);
    expect($('123 Fake St, Testville, TS, 12345'), findsOneWidget);

    // Verify raw coordinates are NOT displayed
    expect($(find.textContaining('Lat: 43.11111')), findsNothing);

    // 5. Submit Course
    // Course name and par values are already initialized correctly.
    // We need to select the number of holes.
    final holesButton = $('18 Holes');
    await $.tester.ensureVisible(holesButton);
    await holesButton.tap();
    await $.pumpAndSettle();

    final saveButton = $('Create Course');
    await $.tester.ensureVisible(saveButton);
    await saveButton.tap();
    await $.pumpAndSettle();

    // Should navigate back to CoursesScreen.
    expect($(AddEditCourseScreen), findsNothing);
    expect($(CoursesScreen), findsOneWidget);

    final createdCourse = $('Test Integration Course');
    expect(createdCourse, findsOneWidget);
    await createdCourse.tap();
    await $.pumpAndSettle();

    expect($(AlertDialog), findsNothing);
    expect($('Test Business Name'), findsOneWidget);
    expect($('Total Par: 54'), findsOneWidget);
  });
}

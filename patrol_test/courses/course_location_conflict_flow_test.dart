// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:mini_golf_tracker/add_edit_course_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return const [
      geocoding.Placemark(
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    GeocodingPlatform.instance = MockGeocodingPlatform();
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
  });

  patrolTest(
      'seeds existing course and bypasses conflict when adding second course at exact same coordinate',
      ($) async {
    // 1. Seed FakeFirebaseFirestore with an existing course at a specific coordinate.
    await fakeFirestore.collection('courses').add({
      'name': 'Chucksters Fire Tower',
      'number_of_holes': 18,
      'latitude': 43.12345,
      'longitude': -71.54321,
      'address': '53 Carter Hill Rd, Hooksett, NH',
      'par_strokes': {'1': 3},
    });

    // 2. Pump AddEditCourseScreen.
    await $.pumpWidgetAndSettle(const MaterialApp(
      home: AddEditCourseScreen(),
    ));
    await $.pump(const Duration(milliseconds: 350));

    // 3. Fill details for a new course at the exact same coordinate.
    await $('18 Holes').tap();
    await $.pump();

    // Enter course name via TextField with hint 'Course Name'
    await $(find.widgetWithText(TextField, 'Course Name'))
        .enterText('Chucksters Case Course');

    // Tap GPS fetch button to assign exact same coordinate from MockGeolocator
    await $(Icons.my_location).tap();
    await $.pump();
    await $.pump(const Duration(milliseconds: 500));

    // 4. Tap "Create Course" to submit the form and trigger the conflict dialog.
    final createCourseBtn = $('Create Course');
    await $.tester.ensureVisible(find.text('Create Course'));
    await createCourseBtn.tap();
    await $.pump();
    await $.pump(const Duration(milliseconds: 500));

    // 5. Verify the Location Conflict dialog appears.
    expect($('Nearby Courses Found'), findsOneWidget);
    expect($('Chucksters Fire Tower'), findsOneWidget);

    // 6. Tap "Add Second Course Anyway".
    final bypassBtn = $('Add Second Course Anyway');
    expect(bypassBtn, findsOneWidget);
    await bypassBtn.tap();
    await $.pump();
    await $.pump(const Duration(milliseconds: 500));

    // 7. Verify the new course is successfully saved to the database.
    final savedCourses = await fakeFirestore.collection('courses').get();
    expect(savedCourses.docs.length, 2);
    expect(
      savedCourses.docs.any((d) => d.get('name') == 'Chucksters Case Course'),
      isTrue,
    );
  });
}

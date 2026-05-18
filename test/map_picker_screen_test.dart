import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mini_golf_tracker/map_picker_screen.dart';

// --- MOCK GEOLOCATOR PLATFORM ---
class MockGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? mockPosition;
  String? exceptionToThrow;
  Duration? positionDelay;

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
    if (positionDelay != null) {
      await Future.delayed(positionDelay!);
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
  List<geocoding.Location>? locationsResult;
  List<geocoding.Placemark>? placemarksResult;
  String? exceptionToThrow;
  Duration? delay;

  @override
  Future<List<geocoding.Location>> locationFromAddress(
    String address, {
    String? localeIdentifier,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (delay != null) {
      await Future.delayed(delay!);
    }
    return locationsResult ?? [
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
    if (delay != null) {
      await Future.delayed(delay!);
    }
    return placemarksResult ?? [
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
  late MockGeolocatorPlatform mockGeolocator;
  late MockGeocodingPlatform mockGeocoding;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;

    mockGeocoding = MockGeocodingPlatform();
    GeocodingPlatform.instance = mockGeocoding;
  });

  Widget createScreen({double? initialLatitude, double? initialLongitude}) {
    return MaterialApp(
      home: MapPickerScreen(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      ),
    );
  }

  testWidgets('renders successfully with initial coordinates and resolves address', (tester) async {
    await tester.pumpWidget(createScreen(initialLatitude: 43.111, initialLongitude: -71.222));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // geocoding resolve

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Select Course Location'), findsOneWidget);
    expect(find.text('53 Carter Hill Rd, Hooksett, NH, 03106'), findsOneWidget);
    expect(find.text('Coordinates: 43.11100, -71.22200'), findsOneWidget);
  });

  testWidgets('initializes without coordinates, successfully fetches GPS and centers map', (tester) async {
    await tester.pumpWidget(createScreen());
    await tester.pump(); // Starts initial locate post-frame callback
    await tester.pump(const Duration(milliseconds: 500)); // Finish locate and geocoding

    expect(find.text('53 Carter Hill Rd, Hooksett, NH, 03106'), findsOneWidget);
    expect(find.text('Coordinates: 43.12345, -71.54321'), findsOneWidget);
  });

  testWidgets('initializes without coordinates, GPS location services disabled, falls back to Hooksett NH', (tester) async {
    mockGeolocator.serviceEnabled = false;

    await tester.pumpWidget(createScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // Finish locate attempt & geocoding fallback

    // Default coordinates: 43.0859, -71.4645
    expect(find.text('Coordinates: 43.08590, -71.46450'), findsOneWidget);
  });

  testWidgets('initializes without coordinates, GPS permissions denied, falls back to Hooksett NH', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.denied;
    mockGeolocator.requestPermissionResult = LocationPermission.denied;

    await tester.pumpWidget(createScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // Finish locate attempt & geocoding fallback

    expect(find.text('Coordinates: 43.08590, -71.46450'), findsOneWidget);
  });

  testWidgets('initializes without coordinates, GPS permissions permanently denied, falls back to Hooksett NH', (tester) async {
    mockGeolocator.checkPermissionResult = LocationPermission.deniedForever;

    await tester.pumpWidget(createScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // Finish locate attempt & geocoding fallback

    expect(find.text('Coordinates: 43.08590, -71.46450'), findsOneWidget);
  });

  testWidgets('locate user via IconButton success', (tester) async {
    // Start with initial coordinates to avoid auto locating fallback on start
    await tester.pumpWidget(createScreen(initialLatitude: 43.111, initialLongitude: -71.222));
    await tester.pump(const Duration(milliseconds: 500));

    // Clicks "Locate Me" button in app bar
    final locateBtn = find.byTooltip('Locate Me');
    expect(locateBtn, findsOneWidget);

    await tester.tap(locateBtn);
    await tester.pump(); // Starts loading state
    await tester.pump(const Duration(milliseconds: 500)); // Ends locate

    expect(find.text('Coordinates: 43.12345, -71.54321'), findsOneWidget);
  });

  testWidgets('locate user via IconButton failure shows SnackBar', (tester) async {
    // Start with initial coordinates
    await tester.pumpWidget(createScreen(initialLatitude: 43.111, initialLongitude: -71.222));
    await tester.pump(const Duration(milliseconds: 500));

    mockGeolocator.exceptionToThrow = 'GPS sensor error';

    final locateBtn = find.byTooltip('Locate Me');
    await tester.tap(locateBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // SnackBar should be displayed
    expect(find.text('Could not get current location: GPS sensor error'), findsOneWidget);
  });

  testWidgets('reverse geocoding returns empty list', (tester) async {
    mockGeocoding.placemarksResult = [];

    await tester.pumpWidget(createScreen(initialLatitude: 43.111, initialLongitude: -71.222));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // geocoding returns empty list

    expect(find.text('Coordinates selected, address not found'), findsOneWidget);
  });

  testWidgets('reverse geocoding throws exception', (tester) async {
    mockGeocoding.exceptionToThrow = 'Geocoding network error';

    await tester.pumpWidget(createScreen(initialLatitude: 43.111, initialLongitude: -71.222));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // geocoding throws

    expect(find.text('Coordinates selected (Reverse geocoding failed)'), findsOneWidget);
  });

  testWidgets('tapping map places pin and reverse geocodes coordinates', (tester) async {
    await tester.pumpWidget(createScreen(initialLatitude: 43.111, initialLongitude: -71.222));
    await tester.pump(const Duration(milliseconds: 500));
    // Find FlutterMap and tap it
    final flutterMap = find.byType(FlutterMap);
    expect(flutterMap, findsOneWidget);

    // Tap at a specific point on FlutterMap
    await tester.tapAt(tester.getCenter(flutterMap));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('53 Carter Hill Rd, Hooksett, NH, 03106'), findsOneWidget);
  });

  testWidgets('Confirm Location pops screen with coordinates and address payload', (tester) async {
    Map<String, dynamic>? resultPayload;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  resultPayload = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen(initialLatitude: 43.111, initialLongitude: -71.222)),
                  );
                },
                child: const Text('Go to picker'),
              ),
            );
          },
        ),
      ),
    );

    // Navigate to picker
    await tester.tap(find.text('Go to picker'));
    await tester.pumpAndSettle(); // geocoding initial load complete

    // Confirm button is present and enabled
    final confirmBtn = find.text('Confirm Location');
    expect(confirmBtn, findsOneWidget);

    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify picker is popped and returns correct payload
    expect(find.byType(MapPickerScreen), findsNothing);
    expect(resultPayload, isNotNull);
    expect(resultPayload!['address'], '53 Carter Hill Rd, Hooksett, NH, 03106');
    expect(resultPayload!['latitude'], 43.111);
    expect(resultPayload!['longitude'], -71.222);
  });

  testWidgets('Confirm Location pops screen with empty address if still resolving or placeholder', (tester) async {
    Map<String, dynamic>? resultPayload;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  resultPayload = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapPickerScreen(initialLatitude: 43.111, initialLongitude: -71.222),
                    ),
                  );
                },
                child: const Text('Go to picker'),
              ),
            );
          },
        ),
      ),
    );

    // Set delay for reverse geocoding to exceed the transition settlement time
    mockGeocoding.delay = const Duration(seconds: 2);

    // Navigate to picker
    await tester.tap(find.text('Go to picker'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // Advance transition but not geocoding

    // Verify it is on MapPickerScreen and showing "Resolving address..."
    expect(find.byType(MapPickerScreen), findsOneWidget);
    expect(find.text('Resolving address...'), findsOneWidget);

    // Confirm button is present and enabled
    final confirmBtn = find.text('Confirm Location');
    expect(confirmBtn, findsOneWidget);

    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify result is empty string for address
    expect(resultPayload, isNotNull);
    expect(resultPayload!['address'], '');
    expect(resultPayload!['latitude'], 43.111);
    expect(resultPayload!['longitude'], -71.222);

    // Advance clock to let the pending geocoding timer complete safely
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('displays CircularProgressIndicator in AppBar during location fetch', (tester) async {
    mockGeolocator.positionDelay = const Duration(seconds: 1);
    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));

    // Tap to locate
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump(); // Start async operation

    // While fetching, it should display the CircularProgressIndicator in the AppBar
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    
    // Allow the geolocator to finish
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}

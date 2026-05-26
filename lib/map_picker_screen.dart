import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mini_golf_tracker/utilities.dart';

class MapPickerScreen extends StatefulWidget {
  @visibleForTesting
  static http.Client? searchClientForTesting;

  @visibleForTesting
  static http.Client Function() searchClientFactoryForTesting =
      _createDefaultSearchClient;

  final double? initialLatitude;
  final double? initialLongitude;
  final http.Client? searchClient;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.searchClient,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _resolvedAddress = '';
  String? _resolvedLocationName;
  bool _isResolvingAddress = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLocatingUser = false;
  List<_NominatimSearchResult> _searchResults = [];

  // Default coordinates to Chucksters in Hooksett, NH if no initial and GPS unavailable
  static const double defaultLat = 43.0859;
  static const double defaultLng = -71.4645;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _reverseGeocode(_selectedLocation!);
    } else {
      // Prompt GPS search immediately to center on user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _locateUser(initial: true);
      });
    }
  }

  Future<void> _locateUser({bool initial = false}) async {
    setState(() {
      _isLocatingUser = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted) return;

      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = userLatLng;
        _isLocatingUser = false;
      });

      _mapController.move(userLatLng, 16.0);
      _reverseGeocode(userLatLng);
    } catch (e) {
      if (!mounted) return;
      Utilities.debugPrintWithCallerInfo(
          "Error getting user location in map picker: $e");
      setState(() {
        _isLocatingUser = false;
      });

      if (initial && _selectedLocation == null) {
        // Fallback to Hooksett, NH
        final fallback = LatLng(defaultLat, defaultLng);
        setState(() {
          _selectedLocation = fallback;
        });
        _mapController.move(fallback, 15.0);
        _reverseGeocode(fallback);
      } else if (!initial) {
        // Only show snackbar if user actively tapped "Locate Me"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _reverseGeocode(LatLng coordinate) async {
    setState(() {
      _isResolvingAddress = true;
      _resolvedAddress = 'Resolving address...';
    });

    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        coordinate.latitude,
        coordinate.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          parts.add(place.postalCode!);
        }

        setState(() {
          _resolvedAddress =
              parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
          _resolvedLocationName = place.name;
          _isResolvingAddress = false;
        });
      } else {
        setState(() {
          _resolvedAddress = 'Coordinates selected, address not found';
          _resolvedLocationName = null;
          _isResolvingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      Utilities.debugPrintWithCallerInfo("Reverse geocoding failed: $e");
      setState(() {
        _resolvedAddress = 'Coordinates selected (Reverse geocoding failed)';
        _resolvedLocationName = null;
        _isResolvingAddress = false;
      });
    }
  }

  Future<void> _searchAddress(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': trimmedQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
      });
      final injectedClient =
          widget.searchClient ?? MapPickerScreen.searchClientForTesting;
      final client =
          injectedClient ?? MapPickerScreen.searchClientFactoryForTesting();
      final response = await client.get(
        uri,
        headers: const {
          'User-Agent': 'mini_golf_tracker/1.0 (course-location-search)',
        },
      );
      if (injectedClient == null) {
        client.close();
      }
      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception('Nominatim returned ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Nominatim response was not a list');
      }
      final results = decoded
          .whereType<Map<String, dynamic>>()
          .map(_NominatimSearchResult.fromJson)
          .whereType<_NominatimSearchResult>()
          .toList();
      if (results.isNotEmpty) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Address not found: $query'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Utilities.debugPrintWithCallerInfo("Search failed: $e");
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _selectSearchResult(_NominatimSearchResult result) {
    final newLatLng = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLocation = newLatLng;
      _resolvedAddress = result.address;
      _resolvedLocationName = result.name;
      _isResolvingAddress = false;
      _searchResults = [];
      _searchController.text = result.displayName;
    });
    _mapController.move(newLatLng, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedLocation != null;
    final initialCenter =
        hasLocation ? _selectedLocation! : LatLng(defaultLat, defaultLng);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Select Course Location',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLocatingUser)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Locate Me',
              onPressed: () => _locateUser(initial: false),
            ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap Tile & Marker layers
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 3.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mrtaz.minigolftracker',
              ),
              if (hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50.0,
                      height: 50.0,
                      alignment: Alignment.bottomCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.red,
                        size: 44.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Search Bar Overlay at Top
          Positioned(
            top: MediaQuery.of(context).padding.top + 56.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search address or location...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) {
                              _searchAddress(value);
                            },
                          ),
                        ),
                        if (_isSearching)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Card(
                    key: const Key('map_search_results'),
                    elevation: 6,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(result.name),
                          subtitle: Text(result.address),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Safe Area overlay at bottom for dynamic card
          Positioned(
            left: 16.0,
            right: 16.0,
            bottom: 30.0,
            child: SafeArea(
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade50],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pin_drop,
                                color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 12.0),
                          const Expanded(
                            child: Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          if (_isResolvingAddress)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        _resolvedAddress.isNotEmpty
                            ? _resolvedAddress
                            : 'Tap anywhere on the map to place a pin and select the course location.',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: _resolvedAddress.isNotEmpty
                              ? Colors.grey.shade800
                              : Colors.grey.shade500,
                          height: 1.4,
                          fontWeight: _resolvedAddress.isNotEmpty
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasLocation) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      const SizedBox(height: 20.0),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasLocation
                                    ? Colors.green.shade700
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              onPressed: hasLocation
                                  ? () {
                                      Navigator.of(context).pop({
                                        'address': _resolvedAddress
                                                    .startsWith('Resolving') ||
                                                _resolvedAddress
                                                    .startsWith('Tap')
                                            ? ''
                                            : _resolvedAddress,
                                        'locationName': _resolvedLocationName,
                                        'latitude': _selectedLocation!.latitude,
                                        'longitude':
                                            _selectedLocation!.longitude,
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                  Icons.check_circle_outline_rounded),
                              label: const Text(
                                'Confirm Location',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// coverage:ignore-start
http.Client _createDefaultSearchClient() => http.Client();
// coverage:ignore-end

class _NominatimSearchResult {
  const _NominatimSearchResult({
    required this.displayName,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  static _NominatimSearchResult? fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    final displayName = json['display_name']?.toString() ?? '';
    if (lat == null || lon == null || displayName.isEmpty) {
      return null;
    }

    final addressJson = json['address'];
    String name = json['name']?.toString() ?? '';
    if (name.isEmpty && addressJson is Map<String, dynamic>) {
      name = (addressJson['leisure'] ??
              addressJson['amenity'] ??
              addressJson['tourism'] ??
              addressJson['shop'] ??
              addressJson['road'] ??
              displayName.split(',').first)
          .toString();
    }
    if (name.isEmpty) {
      name = displayName.split(',').first.trim();
    }

    return _NominatimSearchResult(
      displayName: displayName,
      name: name,
      address: _formatAddress(addressJson, displayName),
      latitude: lat,
      longitude: lon,
    );
  }

  static String _formatAddress(dynamic addressJson, String fallback) {
    if (addressJson is! Map<String, dynamic>) {
      return fallback;
    }

    final houseNumber = addressJson['house_number']?.toString();
    final road = addressJson['road']?.toString();
    final street = [
      if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
      if (road != null && road.isNotEmpty) road,
    ].join(' ');
    final locality =
        addressJson['city'] ?? addressJson['town'] ?? addressJson['village'];
    final state = addressJson['state'];
    final postcode = addressJson['postcode'];
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (locality != null && locality.toString().isNotEmpty)
        locality.toString(),
      if (state != null && state.toString().isNotEmpty) state.toString(),
      if (postcode != null && postcode.toString().isNotEmpty)
        postcode.toString(),
    ];
    return parts.isEmpty ? fallback : parts.join(', ');
  }
}

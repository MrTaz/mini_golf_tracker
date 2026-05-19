import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:mini_golf_tracker/map_picker_screen.dart';

class AddEditCourseScreen extends StatefulWidget {
  final Course? course;

  const AddEditCourseScreen({super.key, this.course});

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _courseName;
  String? _address;
  double? _latitude;
  double? _longitude;
  int? _numberOfHoles;
  late List<int> _parStrokes;
  late final TextEditingController _addressController;

  bool _isFetchingGPS = false;
  String? _gpsError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    if (course != null) {
      _courseName = course.name;
      _address = course.address;
      _latitude = course.latitude;
      _longitude = course.longitude;
      _numberOfHoles = course.numberOfHoles;
      _parStrokes = List.generate(course.numberOfHoles, (index) {
        final holeNumber = index + 1;
        return course.parStrokes[holeNumber] ?? 3;
      });
    } else {
      _courseName = '';
      _address = null;
      _latitude = null;
      _longitude = null;
      _numberOfHoles = null;
      _parStrokes = List.filled(18, 3); // Default to par 3
    }
    _addressController = TextEditingController(text: _address);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectOnMap() async {
    setState(() {
      _gpsError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showAddressCaptureBottomSheet();
        }
        return;
      }
    } catch (e) {
      Utilities.debugPrintWithCallerInfo(
          "Failed to check location permissions: $e");
      if (mounted) {
        _showAddressCaptureBottomSheet();
      }
      return;
    }

    await _openMapScreen();
  }

  Future<void> _openMapScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
        final addr = result['address'] as String?;
        if (addr != null && addr.isNotEmpty) {
          _address = addr;
          _addressController.text = addr;
        }
      });
    }
  }

  void _showAddressCaptureBottomSheet() {
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipController = TextEditingController();
    String? modalError;
    bool isRequestingPermission = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location Access Required',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'The interactive map needs location permissions. You can grant permission to use the map, or fill out this quick address form instead.',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Grant Permission button
                    ElevatedButton.icon(
                      onPressed: isRequestingPermission
                          ? null
                          : () async {
                              setModalState(() {
                                isRequestingPermission = true;
                                modalError = null;
                              });
                              try {
                                LocationPermission permission =
                                    await Geolocator.requestPermission();
                                if (permission ==
                                        LocationPermission.whileInUse ||
                                    permission == LocationPermission.always) {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    await _openMapScreen();
                                  }
                                } else {
                                  setModalState(() {
                                    modalError =
                                        'Location permission denied. Please use the form below.';
                                  });
                                }
                              } catch (e) {
                                setModalState(() {
                                  modalError =
                                      'Could not request permissions: $e';
                                });
                              } finally {
                                setModalState(() {
                                  isRequestingPermission = false;
                                });
                              }
                            },
                      icon: isRequestingPermission
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.map_outlined),
                      label: const Text('Use Map (Grant Permission)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),

                    if (modalError != null) ...[
                      const SizedBox(height: 12.0),
                      Text(
                        modalError!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR FILL IN FORM',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    // Structured Form Fields
                    TextField(
                      controller: streetController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: cityController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'State',
                              hintText: 'e.g. NH',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: zipController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ZIP Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Confirm button
                    ElevatedButton(
                      onPressed: () async {
                        final street = streetController.text.trim();
                        final city = cityController.text.trim();
                        final state = stateController.text.trim();
                        final zip = zipController.text.trim();

                        if (street.isEmpty) {
                          setModalState(() {
                            modalError =
                                'Street address is required to locate the course.';
                          });
                          return;
                        }

                        final parts = <String>[];
                        parts.add(street);
                        if (city.isNotEmpty) parts.add(city);
                        if (state.isNotEmpty) parts.add(state);
                        if (zip.isNotEmpty) parts.add(zip);

                        final fullAddress = parts.join(', ');

                        setState(() {
                          _address = fullAddress;
                          _addressController.text = fullAddress;
                        });

                        Navigator.of(context).pop();

                        // Attempt to geocode in background to pin coordinate
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      'Resolving coordinates for: $fullAddress...'),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        try {
                          final locations =
                              await geocoding.locationFromAddress(fullAddress);
                          if (locations.isNotEmpty && context.mounted) {
                            if (mounted) {
                              setState(() {
                                _latitude = locations.first.latitude;
                                _longitude = locations.first.longitude;
                              });
                            }
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Coordinates successfully resolved and attached for $street!',
                                ),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          }
                        } catch (e) {
                          Utilities.debugPrintWithCallerInfo(
                            "Geocoding of user-captured address failed: $e",
                          );
                          // We don't block the user, just let them know
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Address saved. Map coordinates could not be resolved automatically.',
                                ),
                                backgroundColor: Colors.amber.shade800,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text('Confirm Address'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchGPSLocation() async {
    setState(() {
      _isFetchingGPS = true;
      _gpsError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled on your phone.';
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions were denied.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in your settings.';
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocode to fill in address automatically!
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
            position.latitude, position.longitude);
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

          final resolved = parts.join(', ');
          setState(() {
            _address = resolved;
            _addressController.text = resolved;
          });
        }
      } catch (e) {
        Utilities.debugPrintWithCallerInfo(
            "Reverse geocoding failed in _fetchGPSLocation: $e");
      }

      setState(() {
        _isFetchingGPS = false;
      });
    } catch (e) {
      Utilities.debugPrintWithCallerInfo(
          "Failed to get GPS location in form: $e");
      setState(() {
        _gpsError = e.toString();
        _isFetchingGPS = false;
      });
    }
  }

  Future<List<Course>> _findConflictingCourses(
      double? lat, double? lng, String? address) async {
    final List<Course> conflicts = [];
    if (lat == null &&
        lng == null &&
        (address == null || address.trim().isEmpty)) {
      return conflicts;
    }

    try {
      final allCoursesNullable = await Course.fetchCourses();
      final allCourses = allCoursesNullable.whereType<Course>().toList();

      for (final course in allCourses) {
        bool isConflict = false;
        if (lat != null &&
            lng != null &&
            course.latitude != null &&
            course.longitude != null) {
          try {
            final distance = Geolocator.distanceBetween(
              lat,
              lng,
              course.latitude!,
              course.longitude!,
            );
            if (distance <= 200) {
              isConflict = true;
            }
          } catch (e) {
            Utilities.debugPrintWithCallerInfo(
                "Error calculating distance for conflict check: $e");
          }
        }
        if (!isConflict &&
            address != null &&
            address.trim().isNotEmpty &&
            course.address != null &&
            course.address!.trim().isNotEmpty) {
          if (course.address!.trim().toLowerCase() ==
              address.trim().toLowerCase()) {
            isConflict = true;
          }
        }
        if (isConflict) {
          conflicts.add(course);
        }
      }
    } catch (e) {
      Utilities.debugPrintWithCallerInfo(
          "Error fetching courses for conflict check: $e");
    }

    return conflicts;
  }

  Future<dynamic> _showLocationConflictDialog(List<Course> conflicts) {
    return showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 8.0),
              const Text(
                'Nearby Courses Found',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We found course(s) at or near this location. You can select one of these courses to use, or proceed with adding your second course:',
                  style: TextStyle(fontSize: 14.0, height: 1.4),
                ),
                const SizedBox(height: 16.0),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: conflicts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Course conflictCourse = conflicts[index];
                      return Card(
                        elevation: 1,
                        color: Colors.green.shade50,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          title: Text(
                            conflictCourse.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          subtitle: Text(
                            '${conflictCourse.numberOfHoles} holes'
                            '${conflictCourse.address != null && conflictCourse.address!.isNotEmpty ? '\n${conflictCourse.address}' : ''}',
                            style: TextStyle(
                                height: 1.3, color: Colors.grey.shade800),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.golf_course,
                                color: Colors.green),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.green),
                          onTap: () {
                            Navigator.of(context).pop(conflictCourse);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel
              },
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Add anyway
              },
              child: const Text('Add Second Course Anyway',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDuplicateCourseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8.0),
              const Text('Duplicate Course',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'A course with the same name and number of holes already exists in the database.',
            style: TextStyle(fontSize: 15.0),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_numberOfHoles == null) {
      setState(() {
        _saveError = 'Please select the number of holes.';
      });
      return;
    }

    setState(() {
      _saveError = null;
    });

    double? finalLat = _latitude;
    double? finalLng = _longitude;

    // Geocode address if text is present and GPS is not locked
    if (finalLat == null &&
        finalLng == null &&
        _address != null &&
        _address!.trim().isNotEmpty) {
      try {
        final locations = await geocoding.locationFromAddress(_address!);
        if (locations.isNotEmpty) {
          finalLat = locations.first.latitude;
          finalLng = locations.first.longitude;
          setState(() {
            _latitude = finalLat;
            _longitude = finalLng;
          });
        }
      } catch (e) {
        Utilities.debugPrintWithCallerInfo(
            "Geocoding failed for $_address: $e");
      }
    }

    final conflicts =
        await _findConflictingCourses(finalLat, finalLng, _address);
    if (widget.course != null) {
      // Filter out self when editing
      conflicts.removeWhere((c) => c.id == widget.course!.id);
    }

    dynamic proceed = true;
    if (conflicts.isNotEmpty) {
      proceed = await _showLocationConflictDialog(conflicts);
    }

    if (proceed == null) {
      return; // User cancelled
    }

    if (proceed is Course) {
      // Select the existing course
      if (mounted) {
        Navigator.of(context).pop(proceed);
      }
      return;
    }

    if (proceed == true) {
      final Course savedCourse = Course(
        id: widget.course?.id ?? '',
        name: _courseName,
        numberOfHoles: _numberOfHoles!,
        parStrokes: {
          for (var i = 0; i < _numberOfHoles!; i++) i + 1: _parStrokes[i]
        },
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
      );

      try {
        final result = await savedCourse.saveCourseToDatabase();
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      } catch (e) {
        Utilities.debugPrintWithCallerInfo(
            "Error saving course to database: $e");
        if (mounted) {
          _showDuplicateCourseDialog();
        }
      }
    }
  }

  Widget _buildHoleCountCard(int count) {
    final bool isSelected = _numberOfHoles == count;
    return GestureDetector(
      onTap: () {
        setState(() {
          _numberOfHoles = count;
          _parStrokes = List.filled(count, 3);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.flag_rounded,
              size: 28,
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(height: 8.0),
            Text(
              '$count Holes',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? Colors.green.shade800 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoleStepper(int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.green.shade100, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hole ${index + 1}',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 8.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_parStrokes[index] > 1) {
                        setState(() {
                          _parStrokes[index]--;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove,
                          size: 16, color: Colors.green),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      '${_parStrokes[index]}',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_parStrokes[index] < 6) {
                        setState(() {
                          _parStrokes[index]++;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, size: 16, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Par Stroke',
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.course != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Course' : 'Create New Course',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Backdrop Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.teal.shade600],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32.0),
                  bottomRight: Radius.circular(32.0),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'Make adjustments to your fairway configuration'
                        : 'Enter the details of your new mini-golf course',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inline Error Banner
                    if (_gpsError != null || _saveError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                              color: Colors.red.shade200, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.red.shade700, size: 24),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                _gpsError ?? _saveError ?? '',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.red.shade700, size: 20),
                              onPressed: () {
                                setState(() {
                                  _gpsError = null;
                                  _saveError = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          ],
                        ),
                      ),

                    // Card 1: Course Info
                    Card(
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Course Details',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              initialValue: _courseName,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Course Name',
                                prefixIcon: const Icon(Icons.golf_course,
                                    color: Colors.green),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                      color: Colors.green.shade700, width: 2.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a course name.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _courseName = value!.trim();
                              },
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              controller: _addressController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Address (Optional)',
                                prefixIcon:
                                    const Icon(Icons.map, color: Colors.green),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                      color: Colors.green.shade700, width: 2.0),
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isFetchingGPS)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.green),
                                          ),
                                        ),
                                      )
                                    else ...[
                                      IconButton(
                                        icon: const Icon(Icons.my_location,
                                            color: Colors.green),
                                        tooltip: 'Use Current Location',
                                        onPressed: _fetchGPSLocation,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.map_outlined,
                                            color: Colors.green),
                                        tooltip: 'Select on Map',
                                        onPressed: _selectOnMap,
                                      ),
                                    ],
                                  ],
                                ),
                                helperText: (_latitude != null &&
                                        _longitude != null)
                                    ? 'Coordinates attached. Address is optional.'
                                    : 'Optional address to geolocate.',
                              ),
                              onSaved: (value) {
                                _address = value?.trim();
                              },
                            ),
                            if (_latitude != null && _longitude != null) ...[
                              const SizedBox(height: 12.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.gps_fixed,
                                        color: Colors.green, size: 16),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        'Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _latitude = null;
                                          _longitude = null;
                                        });
                                      },
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        color: Colors.red.shade700,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Card 3: Hole selection & par config
                    Card(
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fairway Par Configuration',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Select the total number of holes and adjust par strokes for each hole below.',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: _buildHoleCountCard(9)),
                                const SizedBox(width: 16.0),
                                Expanded(child: _buildHoleCountCard(18)),
                              ],
                            ),
                            if (_numberOfHoles != null) ...[
                              const SizedBox(height: 24.0),
                              const Divider(),
                              const SizedBox(height: 12.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Adjust Hole Pars',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  Text(
                                    'Total Par: ${_parStrokes.fold<int>(0, (sum, item) => sum + item)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _numberOfHoles!,
                                itemBuilder: (context, index) {
                                  return _buildHoleStepper(index);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Submit Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade700,
                                  Colors.teal.shade600
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              onPressed: _submitForm,
                              child: Text(
                                isEditing ? 'Save Changes' : 'Create Course',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen(
      {super.key, this.creatingGame = false, this.selectedCourse});

  final bool? creatingGame;
  final Course? selectedCourse;

  @override
  CoursesScreenState createState() => CoursesScreenState();
}

class CoursesScreenState extends State<CoursesScreen> {
  late List<Course> courses = [];
  Course? selectedCourse; // Allow null value for selectedCourse

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 5;

  Position? _currentPosition;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    setState(() {
      selectedCourse = widget.selectedCourse;
    });
    _initData();
  }

  Future<void> _initData() async {
    _getCurrentLocation().then((_) {
      if (mounted) {
        _sortCoursesByProximity();
      }
    });
    await _initializeCourses();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocating = false;
        });
      }
    } catch (e) {
      Utilities.debugPrintWithCallerInfo("Failed to get location: $e");
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _sortCoursesByProximity() {
    if (_currentPosition == null || courses.isEmpty) return;
    setState(() {
      courses.sort((a, b) {
        final double? distA = _calculateDistance(a);
        final double? distB = _calculateDistance(b);
        if (distA != null && distB != null) {
          return distA.compareTo(distB);
        } else if (distA != null) {
          return -1; // Location-aware course first
        } else if (distB != null) {
          return 1;
        } else {
          return a.name.compareTo(b.name);
        }
      });
    });
  }

  double? _calculateDistance(Course course) {
    if (_currentPosition == null || course.latitude == null || course.longitude == null) {
      return null;
    }
    try {
      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        course.latitude!,
        course.longitude!,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCourses();
    }
  }



  Future<List<Course>> _initializeCourses() async {
    if (_isLoading) return courses;
    setState(() {
      _isLoading = true;
      courses = [];
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final List<Course> loadedCourses;
      if (_currentPosition != null) {
        Utilities.debugPrintWithCallerInfo("Loading all courses from database for proximity sorting");
        final allCoursesNullable = await Course.fetchCourses();
        loadedCourses = allCoursesNullable.whereType<Course>().toList();
      } else {
        Utilities.debugPrintWithCallerInfo("Loading courses from database (first page)");
        final result = await Course.fetchCoursesPaginated(
          limit: _pageSize,
        );
        loadedCourses = result.courses;
        _lastDocument = result.lastDocument;
      }

      await _saveLocalCourses(loadedCourses); // Save courses locally to keep cache updated

      Utilities.debugPrintWithCallerInfo(
          "Loaded courses from DB: ${loadedCourses.map((course) => course.toJson())}");
      if (mounted) {
        setState(() {
          courses = loadedCourses; // Update the courses list after loading
          if (_currentPosition != null) {
            _hasMore = false;
          } else {
            _hasMore = loadedCourses.length >= _pageSize;
          }
          _isLoading = false;
        });
        _sortCoursesByProximity();
      }
      return loadedCourses;
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          "Exception when loading courses from DB: ${exception.toString()}. Falling back to local cache.");
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String>? coursesJson = prefs.getStringList('courses');
        Utilities.debugPrintWithCallerInfo("Courses saved locally: $coursesJson");
        List<Course> loadedCourses = [];

        if (coursesJson != null) {
          Utilities.debugPrintWithCallerInfo("Loading courses from sharedprefs");
          loadedCourses = coursesJson
              .map((String courseJson) => Course.fromJson(jsonDecode(courseJson)))
              .toList();
        }
        if (mounted) {
          setState(() {
            courses = loadedCourses;
            _hasMore = false; // Disable pagination on local cache fallback
            _isLoading = false;
          });
          _sortCoursesByProximity();
        }
        return loadedCourses;
      } catch (innerException) {
        Utilities.debugPrintWithCallerInfo(
            "Exception when loading courses from local cache: ${innerException.toString()}");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return [];
      }
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Utilities.debugPrintWithCallerInfo("Loading more courses from database");
      final result = await Course.fetchCoursesPaginated(
        startAfter: _lastDocument,
        limit: _pageSize,
      );

      final newCourses = result.courses;
      
      if (mounted) {
        setState(() {
          courses.addAll(newCourses);
          _lastDocument = result.lastDocument;
          _hasMore = newCourses.length >= _pageSize;
          _isLoadingMore = false;
        });
        _sortCoursesByProximity();
      }
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo("Exception when loading more courses: $exception");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false; // Prevent endless retries on failure
        });
      }
    }
  }

  Future<void> _saveLocalCourses(List<Course> coursesToSaveLocally) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> coursesString = coursesToSaveLocally
        .map((course) => jsonEncode(course.toJson()))
        .toList();
    await prefs.setStringList('courses', coursesString);
  }

  Future<bool> _saveCourse(Course course) async {
    try {
      await course.saveCourseToDatabase();
      await _initializeCourses();
      return true;
    } catch (exception) {
      if (!mounted) return false;
      _showDuplicateCourseDialog(context);
      return false;
    }
  }

  void _showDuplicateCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duplicate Course'),
          content: const Text(
              'A course with the same name and number of holes already exists.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCourseListItem(int index) {
    final Course course = courses[index];
    final bool isSelected =
        selectedCourse != null && course.id == selectedCourse!.id;
    
    final double? distanceMeters = _calculateDistance(course);
    String? distanceStr;
    if (distanceMeters != null) {
      final double miles = distanceMeters * 0.000621371;
      distanceStr = '${miles.toStringAsFixed(1)} miles away';
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(course.name),
            subtitle: Text(
              "${course.numberOfHoles} holes"
              "${distanceStr != null ? ' • $distanceStr' : ''}"
              "${course.address != null && course.address!.isNotEmpty ? ' • ${course.address}' : ''}",
            ),
            leading: const Icon(Icons.golf_course),
            selected: isSelected,
            iconColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
              return states.contains(WidgetState.selected)
                  ? Colors.green
                  : Colors.teal;
            }),
            onTap: () => _showCourseDetails(course),
            trailing: widget.creatingGame!
                ? _buildCourseSelectionSwitch(course)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelectionSwitch(Course course) {
    return IconButton(
      icon: const Icon(Icons.check),
      onPressed: () {
        setState(() {
          selectedCourse = course;
          _handleCourseSelection(
              course); // Call the method to handle course selection
        });
      },
    );
  }

  void _handleCourseSelection(Course course) {
    // You can do anything with the selected course here
    Navigator.pop(context, course);
  }

  Future<void> _createNewCourse(BuildContext context) async {
    String courseName = '';
    int? numberOfHoles;
    List<int> parStrokes =
        List.filled(18, 3); // Default par stroke is 3 for each hole

    await showDialog<Course>(
      context: context,
      builder: (BuildContext context) {
        double? dialogLatitude = _currentPosition?.latitude;
        double? dialogLongitude = _currentPosition?.longitude;
        String? dialogAddress;
        bool dialogIsFetchingGPS = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Create New Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                      ),
                      onChanged: (value) {
                        courseName = value;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Address (Optional)',
                        helperText: (dialogLatitude != null && dialogLongitude != null)
                            ? 'Using GPS location. Address is optional.'
                            : 'Enter an address to geolocate this course',
                      ),
                      onChanged: (value) {
                        dialogAddress = value;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: dialogIsFetchingGPS
                                ? null
                                : () async {
                                    setState(() {
                                      dialogIsFetchingGPS = true;
                                    });
                                    try {
                                      bool serviceEnabled =
                                          await Geolocator.isLocationServiceEnabled();
                                      if (!serviceEnabled) {
                                        throw 'Location services are disabled.';
                                      }
                                      LocationPermission permission =
                                          await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied) {
                                        permission = await Geolocator.requestPermission();
                                        if (permission == LocationPermission.denied) {
                                          throw 'Location permission denied.';
                                        }
                                      }
                                      if (permission == LocationPermission.deniedForever) {
                                        throw 'Location permissions are permanently denied.';
                                      }
                                      Position position =
                                          await Geolocator.getCurrentPosition(
                                        locationSettings: const LocationSettings(
                                          accuracy: LocationAccuracy.high,
                                          timeLimit: Duration(seconds: 5),
                                        ),
                                      );
                                      setState(() {
                                        dialogLatitude = position.latitude;
                                        dialogLongitude = position.longitude;
                                        dialogIsFetchingGPS = false;
                                      });
                                    } catch (e) {
                                      Utilities.debugPrintWithCallerInfo(
                                          "Failed to get GPS inside dialog: $e");
                                      setState(() {
                                        dialogIsFetchingGPS = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Failed to get location: $e')),
                                        );
                                      }
                                    }
                                  },
                            icon: dialogIsFetchingGPS
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.green),
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(dialogIsFetchingGPS
                                ? 'Fetching GPS...'
                                : 'Use Current Location'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (dialogLatitude != null && dialogLongitude != null)
                      Text(
                        'Coordinates: ${dialogLatitude!.toStringAsFixed(5)}, ${dialogLongitude!.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        'No location coordinates attached',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<int>(
                      initialValue: numberOfHoles,
                      items: const [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text('Select Number of Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 9,
                          child: Text('9 Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 18,
                          child: Text('18 Holes'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          numberOfHoles = value;
                          parStrokes = List.filled(value!, 3);
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Number of Holes',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    if (numberOfHoles != null)
                      Column(
                        children: List.generate(numberOfHoles!, (index) {
                          return Row(
                            children: [
                              Text('Hole ${index + 1}:'),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: parStrokes[index],
                                  items: List.generate(5, (value) {
                                    return DropdownMenuItem<int>(
                                      value: value + 1,
                                      child: Text('${value + 1}'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setState(() {
                                      parStrokes[index] = value!;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Par',
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                if (numberOfHoles == 9 || numberOfHoles == 18)
                  TextButton(
                    onPressed: () async {
                      if (courseName.isNotEmpty && parStrokes.isNotEmpty) {
                        double? finalLat = dialogLatitude;
                        double? finalLng = dialogLongitude;
                        if (finalLat == null && finalLng == null && dialogAddress != null && dialogAddress!.trim().isNotEmpty) {
                          try {
                            final locations = await geocoding.locationFromAddress(dialogAddress!);
                            if (locations.isNotEmpty) {
                              finalLat = locations.first.latitude;
                              finalLng = locations.first.longitude;
                              dialogLatitude = finalLat;
                              dialogLongitude = finalLng;
                            }
                          } catch (e) {
                            Utilities.debugPrintWithCallerInfo("Geocoding failed for $dialogAddress: $e");
                          }
                        }

                        final conflicts = await _findConflictingCourses(
                          finalLat,
                          finalLng,
                          dialogAddress,
                        );

                        dynamic proceed = true;
                        if (!context.mounted) return;
                        if (conflicts.isNotEmpty) {
                          proceed = await _showLocationConflictDialog(context, conflicts);
                        }

                        if (proceed == null) {
                          // Cancelled
                          return;
                        }

                        if (proceed is Course) {
                          // Select the existing course
                          if (context.mounted) {
                            Navigator.of(context).pop(proceed);
                          }
                          return;
                        }

                        // Otherwise proceed was true, so we create it!
                        final Course newCourse = Course(
                          id: "",
                          name: courseName,
                          numberOfHoles: numberOfHoles!,
                          parStrokes: {
                            for (var holeNumber in List.generate(
                                numberOfHoles!, (index) => index + 1))
                              holeNumber: parStrokes[holeNumber - 1]
                          },
                          latitude: dialogLatitude,
                          longitude: dialogLongitude,
                          address: dialogAddress,
                        );
                        final success = await _saveCourse(newCourse);
                        if (success) {
                          if (!context.mounted) return;
                          Navigator.of(context).pop(newCourse);
                        }
                      }
                    },
                    child: const Text('Create'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCourseDetails(Course course) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(course.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Number of Holes: ${course.numberOfHoles}'),
              if (course.address != null && course.address!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text('Address: ${course.address}'),
              ],
              if (course.latitude != null && course.longitude != null) ...[
                const SizedBox(height: 8.0),
                Text('Coordinates: ${course.latitude!.toStringAsFixed(5)}, ${course.longitude!.toStringAsFixed(5)}'),
              ],
              const SizedBox(height: 16.0),
              ...List.generate(course.numberOfHoles, (index) {
                return _buildHoleDetailsRow(course, index);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close details dialog first
                _editCourse(course);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                _deleteCourse(course);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHoleDetailsRow(Course course, int index) {
    final holeNumber = index + 1;
    final parStroke = course.parStrokes[holeNumber] ?? 3;

    return Row(
      children: [
        Text('Hole $holeNumber:'),
        const SizedBox(width: 8.0),
        Text('Par: $parStroke'),
      ],
    );
  }

  void _editCourse(Course course) async {
    String courseName = course.name;
    int? numberOfHoles = course.numberOfHoles;
    List<int> parStrokes = List.generate(course.numberOfHoles, (index) {
      final holeNumber = index + 1;
      return course.parStrokes[holeNumber] ?? 3;
    });

    await showDialog<Course>(
      context: context,
      builder: (BuildContext context) {
        double? dialogLatitude = course.latitude;
        double? dialogLongitude = course.longitude;
        String? dialogAddress = course.address;
        bool dialogIsFetchingGPS = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                      ),
                      onChanged: (value) {
                        courseName = value;
                      },
                      controller: TextEditingController(text: course.name),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Address (Optional)',
                        helperText: (dialogLatitude != null && dialogLongitude != null)
                            ? 'Using GPS location. Address is optional.'
                            : 'Enter an address to geolocate this course',
                      ),
                      onChanged: (value) {
                        dialogAddress = value;
                      },
                      controller: TextEditingController(text: course.address ?? ''),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: dialogIsFetchingGPS
                                ? null
                                : () async {
                                    setState(() {
                                      dialogIsFetchingGPS = true;
                                    });
                                    try {
                                      bool serviceEnabled =
                                          await Geolocator.isLocationServiceEnabled();
                                      if (!serviceEnabled) {
                                        throw 'Location services are disabled.';
                                      }
                                      LocationPermission permission =
                                          await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied) {
                                        permission = await Geolocator.requestPermission();
                                        if (permission == LocationPermission.denied) {
                                          throw 'Location permission denied.';
                                        }
                                      }
                                      if (permission == LocationPermission.deniedForever) {
                                        throw 'Location permissions are permanently denied.';
                                      }
                                      Position position =
                                          await Geolocator.getCurrentPosition(
                                        locationSettings: const LocationSettings(
                                          accuracy: LocationAccuracy.high,
                                          timeLimit: Duration(seconds: 5),
                                        ),
                                      );
                                      setState(() {
                                        dialogLatitude = position.latitude;
                                        dialogLongitude = position.longitude;
                                        dialogIsFetchingGPS = false;
                                      });
                                    } catch (e) {
                                      Utilities.debugPrintWithCallerInfo(
                                          "Failed to get GPS inside dialog: $e");
                                      setState(() {
                                        dialogIsFetchingGPS = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Failed to get location: $e')),
                                        );
                                      }
                                    }
                                  },
                            icon: dialogIsFetchingGPS
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.green),
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(dialogIsFetchingGPS
                                ? 'Fetching GPS...'
                                : 'Use Current Location'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (dialogLatitude != null && dialogLongitude != null)
                      Text(
                        'Coordinates: ${dialogLatitude!.toStringAsFixed(5)}, ${dialogLongitude!.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        'No location coordinates attached',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<int>(
                      initialValue: numberOfHoles,
                      items: const [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text('Select Number of Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 9,
                          child: Text('9 Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 18,
                          child: Text('18 Holes'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          numberOfHoles = value;
                          parStrokes = List.filled(value!, 3);
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Number of Holes',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    if (numberOfHoles != null)
                      Column(
                        children: List.generate(numberOfHoles!, (index) {
                          return Row(
                            children: [
                              Text('Hole ${index + 1}:'),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: parStrokes[index],
                                  items: List.generate(5, (value) {
                                    return DropdownMenuItem<int>(
                                      value: value + 1,
                                      child: Text('${value + 1}'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setState(() {
                                      parStrokes[index] = value!;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Par',
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                if (numberOfHoles == 9 || numberOfHoles == 18)
                  TextButton(
                    onPressed: () async {
                      if (courseName.isNotEmpty && parStrokes.isNotEmpty) {
                        double? finalLat = dialogLatitude;
                        double? finalLng = dialogLongitude;
                        if (finalLat == null && finalLng == null && dialogAddress != null && dialogAddress!.trim().isNotEmpty) {
                          try {
                            final locations = await geocoding.locationFromAddress(dialogAddress!);
                            if (locations.isNotEmpty) {
                              finalLat = locations.first.latitude;
                              finalLng = locations.first.longitude;
                              dialogLatitude = finalLat;
                              dialogLongitude = finalLng;
                            }
                          } catch (e) {
                            Utilities.debugPrintWithCallerInfo("Geocoding failed for $dialogAddress: $e");
                          }
                        }

                        final conflicts = await _findConflictingCourses(
                          finalLat,
                          finalLng,
                          dialogAddress,
                        );
                        // Filter out the course currently being edited to avoid conflict with itself
                        conflicts.removeWhere((c) => c.id == course.id);

                        dynamic proceed = true;
                        if (!context.mounted) return;
                        if (conflicts.isNotEmpty) {
                          proceed = await _showLocationConflictDialog(context, conflicts);
                        }

                        if (proceed == null) {
                          // Cancelled
                          return;
                        }

                        if (proceed is Course) {
                          // Select the existing course
                          if (context.mounted) {
                            Navigator.of(context).pop(proceed);
                          }
                          return;
                        }

                        if (proceed == true) {
                          final updatedCourse = Course(
                            id: course.id,
                            name: courseName,
                            numberOfHoles: numberOfHoles!,
                            parStrokes: {
                              for (var holeNumber in List.generate(
                                  numberOfHoles!, (index) => index + 1))
                                holeNumber: parStrokes[holeNumber - 1]
                            },
                            latitude: dialogLatitude,
                            longitude: dialogLongitude,
                            address: dialogAddress,
                          );
                          final success = await _saveCourse(updatedCourse);
                          if (success) {
                            if (!context.mounted) return;
                            Navigator.of(context).pop(updatedCourse);
                          }
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Course>> _findConflictingCourses(double? lat, double? lng, String? address) async {
    final List<Course> conflicts = [];
    if (lat == null && lng == null && (address == null || address.trim().isEmpty)) {
      return conflicts;
    }

    List<Course> allCourses = courses;
    if (_hasMore) {
      try {
        final allCoursesNullable = await Course.fetchCourses();
        allCourses = allCoursesNullable.whereType<Course>().toList();
      } catch (e) {
        Utilities.debugPrintWithCallerInfo("Error fetching all courses for conflict check: $e");
      }
    }

    for (final course in allCourses) {
      bool isConflict = false;
      if (lat != null && lng != null && course.latitude != null && course.longitude != null) {
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
          // Ignore proximity errors
        }
      }
      if (!isConflict &&
          address != null &&
          address.trim().isNotEmpty &&
          course.address != null &&
          course.address!.trim().isNotEmpty) {
        if (course.address!.trim().toLowerCase() == address.trim().toLowerCase()) {
          isConflict = true;
        }
      }
      if (isConflict) {
        conflicts.add(course);
      }
    }
    return conflicts;
  }

  Future<dynamic> _showLocationConflictDialog(
      BuildContext context, List<Course> conflicts) {
    return showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 8.0),
              const Text('Nearby Courses Found'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We found the following course(s) at or near this location. You can select one of these to play, or add your new course anyway:',
                  style: TextStyle(fontSize: 14.0),
                ),
                const SizedBox(height: 16.0),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: conflicts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Course conflictCourse = conflicts[index];
                      final double? distanceMeters = _calculateDistance(conflictCourse);
                      String distanceStr = '';
                      if (distanceMeters != null) {
                        final double miles = distanceMeters * 0.000621371;
                        distanceStr = ' • ${miles.toStringAsFixed(1)} miles away';
                      }
                      return Card(
                        color: Colors.green.shade50,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            conflictCourse.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${conflictCourse.numberOfHoles} holes$distanceStr'
                            '${conflictCourse.address != null && conflictCourse.address!.isNotEmpty ? '\n${conflictCourse.address}' : ''}',
                          ),
                          leading: const Icon(Icons.golf_course, color: Colors.green),
                          trailing: const Icon(Icons.chevron_right),
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Add anyway
              },
              child: const Text('Add Second Course Anyway'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCourse(Course course) async {
    try {
      await course.deleteCourseFromDatabase();
      await _initializeCourses();
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          "Exception when deleting course: ${exception.toString()}");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Course?> loadedCourses = await _initializeCourses();
      loadedCourses.removeWhere((c) => c?.id == course.id);

      final List<String> coursesJson =
          loadedCourses.map((course) => jsonEncode(course?.toJson())).toList();
      await prefs.setStringList('courses', coursesJson);

      setState(() {
        courses = loadedCourses.whereType<Course>().toList();
      });
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: (widget.creatingGame!)
          ? AppBar(
              title: const Text('Select Course'),
            )
          : null,
      body: Stack(children: [
        Utilities.backdropImageContinerWidget(),
        if (_isLoading && courses.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20.0,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.green.shade700.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: BouncyAnimation(
                        duration: const Duration(seconds: 1),
                        lift: 50,
                        ratio: 0.25,
                        child: CustomPaint(
                          painter: GolfBallPainter(),
                          child: const SizedBox(width: 60, height: 60),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Preparing the Greens...',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Fetching courses from the fairway...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.green.shade100,
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (!_isLoading && courses.isEmpty)
          _CoursesEmptyState(
            onCreatePressed: () => _createNewCourse(context),
          )
        else
          SafeArea(
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: courses.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (index < courses.length) {
                  return _buildCourseListItem(index);
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewCourse(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CoursesEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _CoursesEmptyState({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_golf,
                  size: 64.0,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'No Courses Yet',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Create a mini-golf course to start tracking scores and comparing stats with your friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28.0),
              ElevatedButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add New Course',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 14.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

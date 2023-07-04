import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course.dart';
import 'course_list_item_widget.dart';

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late List<Course> courses = [];
  Course? selectedCourse; // Allow null value for selectedCourse

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _saveCourse(Course course) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Course> loadedCourses = await _loadCourses();

    if (!_isCourseDuplicate(course, loadedCourses)) {
      loadedCourses.add(course);
      final List<String> coursesJson = loadedCourses.map((course) => jsonEncode(course.toJson())).toList();
      await prefs.setStringList('courses', coursesJson);
      setState(() {
        courses = loadedCourses;
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Duplicate Course'),
            content: const Text('A course with the same name and number of holes already exists.'),
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
  }

  bool _isCourseDuplicate(Course course, List<Course> courses) {
    return courses.any(
      (c) => c.name == course.name && c.numberOfHoles == course.numberOfHoles,
    );
  }

  Future<List<Course>> _loadCourses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? coursesJson = prefs.getStringList('courses');

    if (coursesJson != null) {
      final List<Course> loadedCourses = coursesJson.map((json) => Course.fromMap(jsonDecode(json))).toList();
      setState(() {
        courses = loadedCourses; // Update the courses list after loading
      });
      return loadedCourses; // Return the loaded courses
    }

    return []; // Return an empty list if no courses are found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Course'),
      ),
      body: ListView.builder(
        itemCount: courses.length + 1,
        itemBuilder: (context, index) {
          if (index == courses.length) {
            return ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Course'),
              onTap: () {
                _createNewCourse(context);
              },
            );
          }
          final Course course = courses[index];
          return ListTile(
            title: Text(course.name),
            onTap: () {
              _showCourseDetails(course);
            },
            trailing: _buildCourseSelectionSwitch(course),
          );
        },
      ),
    );
  }

  Widget _buildCourseSelectionSwitch(Course course) {
    return Switch(
      value: selectedCourse == course,
      onChanged: (value) {
        setState(() {
          if (value) {
            selectedCourse = course;
            _handleCourseSelection(course); // Call the method to handle course selection
          } else {
            selectedCourse = null;
          }
        });
      },
    );
  }

  void _handleCourseSelection(Course course) {
    // You can do anything with the selected course here
    Navigator.pop(context, course);
  }

  void _createNewCourse(BuildContext context) async {
    String courseName = '';
    int? numberOfHoles = null;
    List<int> parStrokes = List.filled(18, 3); // Default par stroke is 3 for each hole

    await showDialog<Course>(
      context: context,
      builder: (BuildContext context) {
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
                    DropdownButtonFormField<int>(
                      value: numberOfHoles,
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: const Text('Select Number of Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 9,
                          child: const Text('9 Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 18,
                          child: const Text('18 Holes'),
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
                                  value: parStrokes[index],
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
                        final Course newCourse = Course(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: courseName,
                          numberOfHoles: numberOfHoles!,
                          parStrokes: Map<int, int>.fromIterable(
                            List.generate(numberOfHoles!, (index) => index + 1),
                            key: (holeNumber) => holeNumber,
                            value: (holeNumber) => parStrokes[holeNumber - 1],
                          ),
                        );
                        await _saveCourse(newCourse);
                        Navigator.of(context).pop(newCourse);
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
            children: [
              Text('Number of Holes: ${course.numberOfHoles}'),
              const SizedBox(height: 16.0),
              ...List.generate(course.numberOfHoles, (index) {
                final holeNumber = index + 1;
                final parStroke = course.parStrokes[holeNumber] ?? 3;
                return Row(
                  children: [
                    Text('Hole $holeNumber:'),
                    const SizedBox(width: 8.0),
                    Text('Par: $parStroke'),
                  ],
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
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
                    DropdownButtonFormField<int>(
                      value: numberOfHoles,
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: const Text('Select Number of Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 9,
                          child: const Text('9 Holes'),
                        ),
                        DropdownMenuItem<int>(
                          value: 18,
                          child: const Text('18 Holes'),
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
                                  value: parStrokes[index],
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
                        final updatedCourse = Course(
                          id: course.id,
                          name: courseName,
                          numberOfHoles: numberOfHoles!,
                          parStrokes: Map<int, int>.fromIterable(
                            List.generate(numberOfHoles!, (index) => index + 1),
                            key: (holeNumber) => holeNumber,
                            value: (holeNumber) => parStrokes[holeNumber - 1],
                          ),
                        );
                        await _saveCourse(updatedCourse);
                        Navigator.of(context).pop(updatedCourse);
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

  void _deleteCourse(Course course) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Course> loadedCourses = await _loadCourses();
    loadedCourses.removeWhere((c) => c.id == course.id);

    final List<String> coursesJson = loadedCourses.map((course) => jsonEncode(course.toJson())).toList();
    await prefs.setStringList('courses', coursesJson);

    setState(() {
      courses = loadedCourses;
    });

    Navigator.of(context).pop();
  }
}

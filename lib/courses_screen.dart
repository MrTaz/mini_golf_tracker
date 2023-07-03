import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course.dart';

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late List<Course> courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _saveCourse(Course course) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Course> courses = await _loadCourses();

    courses.add(course);

    final List<String> coursesJson = courses.map((course) => jsonEncode(course.toJson())).toList();
    await prefs.setStringList('courses', coursesJson);
    setState(() {
      this.courses = courses; // Update the courses list after saving
    });
  }

  Future<List<Course>> _loadCourses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? coursesJson = prefs.getStringList('courses');

    if (coursesJson != null) {
      final List<Course> loadedCourses = coursesJson.map((json) => Course.fromMap(jsonDecode(json))).toList();
      setState(() {
        courses = loadedCourses; // Update the courses list after loading
      });
    }

    return [];
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
              Navigator.of(context).pop(course);
            },
          );
        },
      ),
    );
  }

  void _createNewCourse(BuildContext context) async {
    String courseName = '';
    int? numberOfHoles = null;
    List<int> parStrokes = List.filled(18, 3); // Default par stroke is 3 for each hole

    final newCourse = await showDialog<Course>(
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

    if (newCourse != null) {
      Navigator.of(context).pop(newCourse);
    }
  }
}

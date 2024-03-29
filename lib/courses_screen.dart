import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key, this.creatingGame = false, this.selectedCourse});

  final bool? creatingGame;
  final Course? selectedCourse;

  @override
  CoursesScreenState createState() => CoursesScreenState();
}

class CoursesScreenState extends State<CoursesScreen> {
  late List<Course> courses = [];
  Course? selectedCourse; // Allow null value for selectedCourse
  bool showCloseButton = false;
  bool showCreateForm = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeCourses();
    setState(() {
      selectedCourse = widget.selectedCourse;
    });
  }

  void fabPressed() {
    setState(() {
      showCreateForm = true;
      showCloseButton = true;
    });
  }

  void closeCreateScreen() {
    setState(() {
      showCreateForm = false;
      showCloseButton = false;
    });
  }

  Future<List<Course?>> _initializeCourses() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? coursesJson = prefs.getStringList('courses');
      Utilities.debugPrintWithCallerInfo("Courses saved locally: $coursesJson");
      List<Course> loadedCourses = [];

      if (coursesJson != null) {
        Utilities.debugPrintWithCallerInfo("Loading courses from sharedprefs");
        loadedCourses = coursesJson.map((String courseJson) => Course.fromJson(jsonDecode(courseJson))).toList();
      } else {
        Utilities.debugPrintWithCallerInfo("Loading courses from database");
        final List<Course?> dbcourses = await Course.fetchCourses();
        if (dbcourses.isNotEmpty) {
          loadedCourses = dbcourses.whereType<Course>().toList();
          await _saveLocalCourses(loadedCourses); //save courses locally if we loaded them from db
        }
      }
      Utilities.debugPrintWithCallerInfo("Loaded courses: ${loadedCourses.map((course) => course.toJson())}");
      setState(() {
        courses = loadedCourses; // Update the courses list after loading
      });
      return loadedCourses; // Returns an empty list if no courses are found
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo("Exception when loading courses: ${exception.toString()}");
      return [];
    }
  }

  Future<void> _saveLocalCourses(List<Course> coursesToSaveLocally) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> coursesString = coursesToSaveLocally.map((course) => jsonEncode(course.toJson())).toList();
    await prefs.setStringList('courses', coursesString);
  }

  Future<void> _saveCourse(Course course) async {
    try {
      final Course updatedCourse = await course.saveCourseToDatabase();
      final List<Course?> loadedCourses = await _initializeCourses();
      loadedCourses.add(updatedCourse);

      await _saveLocalCourses(loadedCourses.whereType<Course>().toList());
      setState(() {
        courses = loadedCourses.whereType<Course>().toList();
      });
    } catch (exception) {
      _showDuplicateCourseDialog(context);
    }
  }

  void _showDuplicateCourseDialog(BuildContext context) {
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

  Widget _buildCourseListItem(int index) {
    final Course course = courses[index];
    final bool isSelected = selectedCourse != null && course.id == selectedCourse!.id;

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(course.name),
            subtitle: Text("${course.numberOfHoles} holes"),
            leading: const Icon(Icons.golf_course),
            selected: isSelected,
            iconColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
              return states.contains(MaterialState.selected) ? Colors.green : Colors.teal;
            }),
            onTap: () => _showCourseDetails(course),
            // trailing: _buildCourseSelectionSwitch(course)
            trailing: widget.creatingGame! ? _buildCourseSelectionSwitch(course) : null,
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
          _handleCourseSelection(course); // Call the method to handle course selection
        });
      },
    );
  }

  void _handleCourseSelection(Course course) {
    // You can do anything with the selected course here
    Navigator.pop(context, course);
  }

  _createNewCourse(BuildContext context) async {
    String courseName = '';
    int? numberOfHoles;
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
                          id: 0, //DateTime.now().millisecondsSinceEpoch,
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
                return _buildHoleDetailsRow(course, index);
                // final holeNumber = index + 1;
                // final parStroke = course.parStrokes[holeNumber] ?? 3;
                // return Row(
                //   children: [
                //     Text('Hole $holeNumber:'),
                //     const SizedBox(width: 8.0),
                //     Text('Par: $parStroke'),
                //   ],
                // );
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
    final List<Course?> loadedCourses = await _initializeCourses();
    loadedCourses.removeWhere((c) => c?.id == course.id);

    final List<String> coursesJson = loadedCourses.map((course) => jsonEncode(course?.toJson())).toList();
    await prefs.setStringList('courses', coursesJson);

    setState(() {
      courses = loadedCourses.whereType<Course>().toList();
      ;
    });

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
        SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: showCreateForm
                ? _createNewCourse(context)
                : Column(
                    children: <Widget>[
                      ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(0.8),
                        itemCount: courses.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _buildCourseListItem(index);
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: showCloseButton ? closeCreateScreen : () => _createNewCourse(context),
        child: showCloseButton ? const Icon(Icons.close) : const Icon(Icons.add),
      ),
    );
  }
}

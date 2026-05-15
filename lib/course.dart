import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  Course({
    required this.id,
    required this.name,
    required this.numberOfHoles,
    required this.parStrokes,
  });

  factory Course.empty() {
    return Course(id: '', name: '', numberOfHoles: 0, parStrokes: {});
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] ?? '';
    final String name = json['name'] ?? '';
    final int numberOfHoles = json['number_of_holes'] ?? 0;
    final Map<int, int> parStrokes = (json['par_strokes'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(int.parse(key), value as int)) ??
        {};

    return Course(
      id: id,
      name: name,
      numberOfHoles: numberOfHoles,
      parStrokes: parStrokes,
    );
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    final parStrokes = (map['parStrokes'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(int.parse(key), value as int));

    return Course(
      id: map['id'] as String,
      name: map['name'] as String,
      numberOfHoles: map['numberOfHoles'] as int,
      parStrokes: parStrokes,
    );
  }

  final String id;
  String name;
  final int numberOfHoles;
  final Map<int, int> parStrokes; // Map to store par strokes for each hole

  FirebaseFirestore get db => DatabaseConnection.client;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number_of_holes': numberOfHoles,
      'par_strokes': Map<String, int>.from(
          parStrokes.map((key, value) => MapEntry(key.toString(), value))),
    };
  }

  int getParValue(int holeNumber) {
    if (parStrokes.containsKey(holeNumber)) {
      return parStrokes[holeNumber]!;
    } else {
      throw Exception('Invalid hole number');
    }
  }

  static Future<List<Course?>> fetchCourses() async {
    try {
      // Fetch the courses from the database
      final snapshot = await DatabaseConnection.client.collection('courses').get();
      final courses = snapshot.docs.map<Course?>((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return Course.fromJson(data);
      }).toList();

      Utilities.debugPrintWithCallerInfo(
          "Recieved courses: ${courses.map((course) => course?.toJson())}");

      return courses;
    } on FirebaseException catch (e) {
      // Handle error if any
      if (kDebugMode) {
        print('Error fetching courses: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to fetch courses: ${e.message}');
    }
  }

  Future<Course> saveCourseToDatabase() async {
    try {
      // Fetch existing courses with the same name from the database
      final existingCoursesSnapshot = await db
          .collection('courses')
          .where('name', isEqualTo: name)
          .where('number_of_holes', isEqualTo: numberOfHoles)
          .limit(1)
          .get();

      // If there's an existing course with the same name and number of holes, do not save
      if (existingCoursesSnapshot.docs.isNotEmpty) {
        throw Exception(
            'Course with the same name and number of holes already exists.');
      }

      // Prepare the course data to be saved
      final courseData = {
        'name': name,
        'number_of_holes': numberOfHoles,
        'par_strokes': Map<String, int>.from(
            parStrokes.map((key, value) => MapEntry(key.toString(), value))),
      };

      // Save the course data to the database
      final docRef = await db.collection('courses').add(courseData);
      var docSnapshot = await docRef.get();
      var data = docSnapshot.data()!;
      data['id'] = docRef.id;

      final updatedCourse = Course.fromJson(data);
      Utilities.debugPrintWithCallerInfo(
          "Updated course returned: ${updatedCourse.toJson()}");

      return updatedCourse;
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to save course: ${e.message}');
      throw DatabaseConnectionError('Failed to save course: ${e.message}');
    }
  }
}

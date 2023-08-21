import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Course {
  final int id;
  String name;
  final int numberOfHoles;
  final Map<int, int> parStrokes; // Map to store par strokes for each hole

  Course({
    required this.id,
    required this.name,
    required this.numberOfHoles,
    required this.parStrokes,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    final parStrokes =
        (map['parStrokes'] as Map<String, dynamic>).map((key, value) => MapEntry(int.parse(key), value as int));

    return Course(
      id: map['id'] as int,
      name: map['name'] as String,
      numberOfHoles: map['numberOfHoles'] as int,
      parStrokes: parStrokes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number_of_holes': numberOfHoles,
      'par_strokes': Map<String, int>.from(parStrokes.map((key, value) => MapEntry(key.toString(), value))),
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final int id = json['id'];
    final String name = json['name'];
    final int numberOfHoles = json['number_of_holes'];
    final Map<int, int> parStrokes =
        (json['par_strokes'] as Map<String, dynamic>).map((key, value) => MapEntry(int.parse(key), value as int));

    return Course(
      id: id,
      name: name,
      numberOfHoles: numberOfHoles,
      parStrokes: parStrokes,
    );
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
      final response = await db.from('courses').select('*');
      final coursesData = response as List<dynamic>;
      final courses = coursesData.map<Course?>((data) => Course.fromJson(data as Map<String, dynamic>)).toList();

      Utilities.debugPrintWithCallerInfo("Recieved courses: ${courses.map((course) => course?.toJson())}");

      return courses;
    } on PostgrestException catch (e) {
      // Handle error if any
      if (kDebugMode) {
        print('Error fetching courses: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to fetch courses: ${e.message}');
      // return [];
    }
  }

  // Future<Course> fetchCourseDetails(int selectedCourseId) async {
  //   try {
  //     final response = await supabase.from('courses').select().eq('id', selectedCourseId).single();
  //     final courseData = response.data;
  //     if (courseData == null) {
  //       throw DatabaseConnectionError('Course not found: $selectedCourseId');
  //     }

  //     final course = Course.fromMap(courseData);
  //     return course;
  //   } on PostgrestException catch (e) {
  //     // Handle error if any
  //     if (kDebugMode) {
  //       print('Error fetching courses: ${e.message}');
  //     }
  //     throw DatabaseConnectionError('Failed to fetch courses: ${e.message}');
  //   }
  // }

  Future<Course> saveCourseToDatabase() async {
    try {
      // Fetch existing courses with the same name from the database
      final existingCoursesResponse =
          await db.from('courses').select('id').eq('name', name).eq('number_of_holes', numberOfHoles).limit(1);

      // If there's an existing course with the same name and number of holes, do not save
      if (existingCoursesResponse.isNotEmpty) {
        throw Exception('Course with the same name and number of holes already exists.');
      }

      // Prepare the course data to be saved
      final courseData = {
        'name': name,
        'number_of_holes': numberOfHoles,
        'par_strokes': Map<String, int>.from(parStrokes.map((key, value) => MapEntry(key.toString(), value))),
      };

      // Save the course data to the database
      final updatedCourse = await db.from('courses').insert([courseData]).select().single();
      Utilities.debugPrintWithCallerInfo("Updated course returned: $updatedCourse");

      return Course.fromJson(updatedCourse); 
    } on PostgrestException catch (e) {
      Utilities.debugPrintWithCallerInfo('Failed to save course: ${e.message}');
      throw DatabaseConnectionError('Failed to save course: ${e.message}');
    }
  }
}

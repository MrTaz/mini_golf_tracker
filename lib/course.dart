import 'package:flutter/foundation.dart';
import 'package:mini_golf_tracker/databaseconnectionerror.dart';
import 'package:supabase/supabase.dart';

import 'main.dart';

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
      'numberOfHoles': numberOfHoles,
      'parStrokes': Map<String, int>.from(parStrokes.map((key, value) => MapEntry(key.toString(), value))),
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final int id = json['id'];
    final String name = json['name'];
    final int numberOfHoles = json['numberOfHoles'];
    final Map<int, int> parStrokes =
        (json['parStrokes'] as Map<String, dynamic>).map((key, value) => MapEntry(int.parse(key), value as int));

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

  Future<List<String>> fetchCourses() async {
    try {
      // Fetch the courses from the database
      final response = await supabase.from('courses').select('name');
      // Extract the course names from the response
      final courses = response.data.map((row) => row['name'] as String).toList();

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

  Future<Course> fetchCourseDetails(int selectedCourseId) async {
    try {
      final response = await supabase.from('courses').select().eq('id', selectedCourseId).single();
      final courseData = response.data;
      if (courseData == null) {
        throw DatabaseConnectionError('Course not found: $selectedCourseId');
      }

      final course = Course.fromMap(courseData);
      return course;
    } on PostgrestException catch (e) {
      // Handle error if any
      if (kDebugMode) {
        print('Error fetching courses: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to fetch courses: ${e.message}');
    }
  }

  Future<void> saveCourseToDatabase() async {
    try {
      // Fetch existing courses with the same name from the database
      final existingCoursesResponse =
          await supabase.from('courses').select('id').eq('name', name).eq('number_of_holes', numberOfHoles).limit(1);

      // If there's an existing course with the same name and number of holes, do not save
      if (existingCoursesResponse.isNotEmpty) {
        throw Exception('Course with the same name and number of holes already exists.');
      }

      // Prepare the course data to be saved
      final courseData = {
        'name': name,
        'number_of_holes': numberOfHoles,
        'parStrokes': parStrokes,
      };

      // Save the course data to the database
      final response = await supabase.from('courses').insert([courseData]).select();

      // Handle success response here
    } on PostgrestException catch (e) {
      // Handle error if any
      if (kDebugMode) {
        print('Failed to save course: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to save course: ${e.message}');
    }
  }
}

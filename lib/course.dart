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
    this.latitude,
    this.longitude,
    this.address,
  });

  factory Course.empty() {
    return Course(
      id: '',
      name: '',
      numberOfHoles: 0,
      parStrokes: {},
      latitude: null,
      longitude: null,
      address: null,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] ?? '';
    final String name = json['name'] ?? '';
    final int numberOfHoles = _parseInt(json['number_of_holes'] ?? json['numberOfHoles']);
    
    final Map<int, int> parStrokes = {};
    final dynamic rawParStrokes = json['par_strokes'] ?? json['parStrokes'];
    if (rawParStrokes is Map) {
      rawParStrokes.forEach((key, value) {
        final int? parsedKey = int.tryParse(key.toString()) ?? double.tryParse(key.toString())?.toInt();
        final int? parsedValue = value is int
            ? value
            : value is double
                ? value.toInt()
                : int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt();
        if (parsedKey != null && parsedValue != null) {
          parStrokes[parsedKey] = parsedValue;
        }
      });
    }

    final double? latitude = json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null;
    final double? longitude = json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null;
    final String? address = json['address'] as String?;

    return Course(
      id: id,
      name: name,
      numberOfHoles: numberOfHoles,
      parStrokes: parStrokes,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    final String id = map['id'] as String? ?? '';
    final String name = map['name'] as String? ?? '';
    final int numberOfHoles = _parseInt(map['numberOfHoles'] ?? map['number_of_holes']);

    final Map<int, int> parStrokes = {};
    final dynamic rawParStrokes = map['parStrokes'] ?? map['par_strokes'];
    if (rawParStrokes is Map) {
      rawParStrokes.forEach((key, value) {
        final int? parsedKey = int.tryParse(key.toString()) ?? double.tryParse(key.toString())?.toInt();
        final int? parsedValue = value is int
            ? value
            : value is double
                ? value.toInt()
                : int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt();
        if (parsedKey != null && parsedValue != null) {
          parStrokes[parsedKey] = parsedValue;
        }
      });
    }

    final double? latitude = map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null;
    final double? longitude = map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null;
    final String? address = map['address'] as String?;

    return Course(
      id: id,
      name: name,
      numberOfHoles: numberOfHoles,
      parStrokes: parStrokes,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  final String id;
  String name;
  final int numberOfHoles;
  final Map<int, int> parStrokes; // Map to store par strokes for each hole
  final double? latitude;
  final double? longitude;
  final String? address;

  FirebaseFirestore get db => DatabaseConnection.client;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number_of_holes': numberOfHoles,
      'par_strokes': Map<String, int>.from(
          parStrokes.map((key, value) => MapEntry(key.toString(), value))),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
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
      // Prepare the course data to be saved
      final courseData = {
        'name': name,
        'number_of_holes': numberOfHoles,
        'par_strokes': Map<String, int>.from(
            parStrokes.map((key, value) => MapEntry(key.toString(), value))),
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

      if (id.isNotEmpty) {
        // Edit/update existing course
        await db.collection('courses').doc(id).set(courseData, SetOptions(merge: true));
        return this;
      } else {
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

        // Save the course data to the database
        final docRef = await db.collection('courses').add(courseData);
        var docSnapshot = await docRef.get();
        var data = docSnapshot.data()!;
        data['id'] = docRef.id;

        final updatedCourse = Course.fromJson(data);
        Utilities.debugPrintWithCallerInfo(
            "Updated course returned: ${updatedCourse.toJson()}");

        return updatedCourse;
      }
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Failed to save course: ${e.message}');
      throw DatabaseConnectionError('Failed to save course: ${e.message}');
    }
  }

  Future<void> deleteCourseFromDatabase() async {
    try {
      await db.collection('courses').doc(id).delete();
      Utilities.debugPrintWithCallerInfo("Deleted course: $id");
    } on FirebaseException catch (e) {
      Utilities.debugPrintWithCallerInfo('Failed to delete course: ${e.message}');
      throw DatabaseConnectionError('Failed to delete course: ${e.message}');
    }
  }

  static Future<CourseFetchResult> fetchCoursesPaginated({
    DocumentSnapshot? startAfter,
    required int limit,
  }) async {
    try {
      Query query = DatabaseConnection.client.collection('courses').orderBy('name');
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      query = query.limit(limit);

      final snapshot = await query.get();
      final coursesList = snapshot.docs.map<Course>((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Course.fromJson(data);
      }).toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      return CourseFetchResult(courses: coursesList, lastDocument: lastDoc);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Error fetching courses paginated: ${e.message}');
      }
      throw DatabaseConnectionError('Failed to fetch courses: ${e.message}');
    }
  }
}

class CourseFetchResult {
  final List<Course> courses;
  final DocumentSnapshot? lastDocument;

  CourseFetchResult({required this.courses, this.lastDocument});
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}

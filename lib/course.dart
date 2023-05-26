class Course {
  final int id;
  final String name;
  final int numberOfHoles;
  final Map<int, int> parStrokes; // Map to store par strokes for each hole

  Course({
    required this.id,
    required this.name,
    required this.numberOfHoles,
    required this.parStrokes,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int,
      name: map['name'] as String,
      numberOfHoles: map['numberOfHoles'] as int,
      parStrokes: Map<int, int>.from(map['parStrokes']),
    );
  }
}

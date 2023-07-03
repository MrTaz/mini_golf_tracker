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
      'parStrokes': parStrokes.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  int getParValue(int holeNumber) {
    if (parStrokes.containsKey(holeNumber)) {
      return parStrokes[holeNumber]!;
    } else {
      throw Exception('Invalid hole number');
    }
  }
}

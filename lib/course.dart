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
}

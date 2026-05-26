import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';

class CourseListItem extends StatefulWidget {
  const CourseListItem({
    super.key,
    required this.course,
    required this.onDelete,
    required this.onModify,
  });

  final Course course;
  final VoidCallback onDelete;
  final VoidCallback onModify;

  @override
  CourseListItemState createState() => CourseListItemState();
}

class CourseListItemState extends State<CourseListItem> {
  bool showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
            title: Text(
              'Course: ${widget.course.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              ListTile(
                title: Text('Number of Holes: ${widget.course.numberOfHoles}'),
              ),
              ListTile(
                  title: const Text('Par Values:', style: TextStyle(fontSize: 16)),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.course.locationName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text('Location: ${widget.course.locationName}',
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                              'Total Par: ${widget.course.parStrokes.values.fold<int>(0, (sum, val) => sum + val)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Wrap(
                          spacing: 16.0,
                          runSpacing: 12.0,
                          children: List.generate(widget.course.numberOfHoles, (index) {
                            final holeNumber = index + 1;
                            final parValue = widget.course.parStrokes[holeNumber] ?? 0;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Hole $holeNumber',
                                    style: const TextStyle(fontSize: 12)),
                                Text('Par: $parValue',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            );
                          }),
                        )
                      ]))
            ]),
      ],
    );
  }
}

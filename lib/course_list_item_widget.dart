import 'package:flutter/material.dart';

import 'course.dart';

class CourseListItem extends StatefulWidget {
  final Course course;
  final VoidCallback onDelete;
  final VoidCallback onModify;

  const CourseListItem({
    required this.course,
    required this.onDelete,
    required this.onModify,
  });

  @override
  _CourseListItemState createState() => _CourseListItemState();
}

class _CourseListItemState extends State<CourseListItem> {
  bool showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(widget.course.name),
          onTap: () {
            setState(() {
              showDetails = !showDetails;
            });
          },
        ),
        if (showDetails) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Number of Holes: ${widget.course.numberOfHoles}'),
                Text('Par Strokes: ${widget.course.parStrokes.values.join(', ')}'),
                Row(
                  children: [
                    TextButton(
                      onPressed: widget.onModify,
                      child: const Text('Modify'),
                    ),
                    TextButton(
                      onPressed: widget.onDelete,
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ],
    );
  }
}

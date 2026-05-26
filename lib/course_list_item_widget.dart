import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';

class CourseListItem extends StatefulWidget {
  const CourseListItem({
    super.key,
    required this.course,
    required this.onDelete,
    required this.onModify,
    this.trailing,
    this.selected = false,
    this.distanceMeters,
  });

  final Course course;
  final VoidCallback onDelete;
  final VoidCallback onModify;
  final Widget? trailing;
  final bool selected;
  final double? distanceMeters;

  @override
  CourseListItemState createState() => CourseListItemState();
}

class CourseListItemState extends State<CourseListItem> {
  bool showDetails = false;

  @override
  Widget build(BuildContext context) {
    final distanceText = widget.distanceMeters == null
        ? null
        : '${(widget.distanceMeters! * 0.000621371).toStringAsFixed(1)} miles away';

    return Column(
      children: [
        ExpansionTile(
            leading: Icon(
              Icons.golf_course,
              color: widget.selected ? Colors.green : Colors.teal,
            ),
            title: Text(
              'Course: ${widget.course.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${widget.course.numberOfHoles} holes"
              "${distanceText != null ? ' • $distanceText' : ''}"
              "${widget.course.address != null && widget.course.address!.isNotEmpty ? ' • ${widget.course.address}' : ''}",
            ),
            trailing: widget.trailing,
            children: [
              ListTile(
                title: Text('Number of Holes: ${widget.course.numberOfHoles}'),
              ),
              if (widget.course.address != null &&
                  widget.course.address!.isNotEmpty)
                ListTile(
                  title: Text('Address: ${widget.course.address}'),
                ),
              ListTile(
                  title:
                      const Text('Par Values:', style: TextStyle(fontSize: 16)),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.course.locationName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                                'Location: ${widget.course.locationName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                              'Total Par: ${widget.course.parStrokes.values.fold<int>(0, (sum, val) => sum + val)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Wrap(
                          spacing: 16.0,
                          runSpacing: 12.0,
                          children: List.generate(widget.course.numberOfHoles,
                              (index) {
                            final holeNumber = index + 1;
                            final parValue =
                                widget.course.parStrokes[holeNumber] ?? 0;
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
                      ])),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onModify,
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: widget.onDelete,
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ]),
      ],
    );
  }
}

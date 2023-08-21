import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';

class CourseListItem extends StatefulWidget {
  final Course course;
  final VoidCallback onDelete;
  final VoidCallback onModify;

  const CourseListItem({
    Key? key, 
    required this.course,
    required this.onDelete,
    required this.onModify,
  }): super(key: key);

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
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.course.numberOfHoles,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                        childAspectRatio: 3.0,
                      ),
                      itemBuilder: (context, index) {
                        final holeNumber = index + 1;
                        final parValue = widget.course.getParValue(holeNumber);
                        return Column(
                          children: [
                            Text('Hole $holeNumber', style: const TextStyle(fontSize: 12)),
                            Text('Par: $parValue', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        );
                      },
                    )
                  ]))
            ]),
      ],
    );
  }
}

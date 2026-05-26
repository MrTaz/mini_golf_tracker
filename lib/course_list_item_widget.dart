import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _launchAddress() async {
    final address = widget.course.address;
    if (address == null || address.isEmpty) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = widget.distanceMeters == null
        ? null
        : '${(widget.distanceMeters! * 0.000621371).toStringAsFixed(1)} miles away';
    final hasAddress =
        widget.course.address != null && widget.course.address!.isNotEmpty;

    return Column(
      children: [
        ExpansionTile(
            leading: Icon(
              Icons.golf_course,
              color: widget.selected ? Colors.green : Colors.teal,
            ),
            title: Text(
              widget.course.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.course.numberOfHoles} holes"
                  "${distanceText != null ? ' • $distanceText' : ''}",
                ),
                if (hasAddress)
                  InkWell(
                    key: const Key('course_address_map_link'),
                    onTap: _launchAddress,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.course.address!,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            trailing: widget.trailing,
            children: [
              ListTile(
                  title:
                      const Text('Par Values:', style: TextStyle(fontSize: 16)),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.course.locationName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(widget.course.locationName!,
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
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: widget.course.numberOfHoles,
                          itemBuilder: (context, index) {
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
                          },
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

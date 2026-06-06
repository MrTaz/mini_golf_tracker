import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/core/physics/extra_scroll_physics_class.dart';

void main() {
  testWidgets('OverscrollList renders and accepts pointer signals',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OverscrollList(),
      ),
    ));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(Container), findsWidgets);

    final customScrollView =
        tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(customScrollView.physics, isNotNull);
  });

  testWidgets('OverscrollList handles web pointer signal',
      (WidgetTester tester) async {
    isWebOverride = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OverscrollList(),
      ),
    ));

    final Offset scrollDelta = const Offset(0, 50);
    final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(const Offset(10, 10));

    await tester.sendEventToBinding(PointerScrollEvent(
      position: const Offset(10, 10),
      scrollDelta: scrollDelta,
    ));
    await tester.pump();

    final customScrollView =
        tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(customScrollView.physics, isNotNull);
    isWebOverride = false;
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/core/animations/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/core/config/asset_golf_ball_path.dart';

void main() {
  group('GolfBallPainter', () {
    test('shouldRepaint returns false', () {
      final painter = GolfBallPainter();
      expect(painter.shouldRepaint(GolfBallPainter()), isFalse);
    });

    testWidgets('paints golf ball on canvas successfully without throwing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                painter: GolfBallPainter(),
                size: const Size(100, 100),
              ),
            ),
          ),
        ),
      );

      // Verify that a CustomPaint widget with a GolfBallPainter exists and is rendered
      expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is GolfBallPainter),
        findsOneWidget,
      );
    });
  });

  group('BouncyAnimation', () {
    testWidgets('animates bouncy child successfully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncyAnimation(
                duration: Duration(milliseconds: 500),
                lift: 40.0,
                pause: 0.1,
                ratio: 0.5,
                child: SizedBox(width: 50, height: 50, key: Key('bouncy_box')),
              ),
            ),
          ),
        ),
      );

      // Verify child is rendered
      expect(find.byKey(const Key('bouncy_box')), findsOneWidget);

      // Tick the animation forward frame-by-frame instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}

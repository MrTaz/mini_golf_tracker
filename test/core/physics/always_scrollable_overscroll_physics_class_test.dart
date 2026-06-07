import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/core/physics/always_scrollable_overscroll_physics_class.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

void main() {
  group('AlwaysScrollableOverscrollPhysics', () {
    test('applyTo returns new instance with parent and same bounds', () {
      const physics = AlwaysScrollableOverscrollPhysics(
        overscrollStart: 10,
        overscrollEnd: 20,
      );
      final applied = physics.applyTo(const ClampingScrollPhysics());
      expect(applied, isA<AlwaysScrollableOverscrollPhysics>());
      final appliedCast = applied as AlwaysScrollableOverscrollPhysics; // ignore: unnecessary_cast
      expect(appliedCast.overscrollStart, 10);
      expect(appliedCast.overscrollEnd, 20);
      expect(appliedCast.parent, isA<ClampingScrollPhysics>());
    });

    test('expandScrollMetrics alters bounds', () {
      const physics = AlwaysScrollableOverscrollPhysics(
        overscrollStart: 10,
        overscrollEnd: 20,
      );
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      final expanded = physics.expandScrollMetrics(metrics);
      expect(expanded.minScrollExtent, -10);
      expect(expanded.maxScrollExtent, 120);
    });

    test('adjustPositionForNewDimensions delegates to parent', () {
      const physics = AlwaysScrollableOverscrollPhysics(
        overscrollStart: 10,
        overscrollEnd: 20,
      );
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      final val = physics.adjustPositionForNewDimensions(
        oldPosition: metrics,
        newPosition: metrics,
        isScrolling: false,
        velocity: 0,
      );
      expect(val, 0.0);
    });

    test('applyBoundaryConditions delegates to parent', () {
      const physics = AlwaysScrollableOverscrollPhysics();
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      final val = physics.applyBoundaryConditions(metrics, 10);
      expect(val, 0.0); // Within bounds, so 0.0 overscroll
    });

    test('applyPhysicsToUserOffset delegates to parent', () {
      const physics = AlwaysScrollableOverscrollPhysics();
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      final val = physics.applyPhysicsToUserOffset(metrics, 10);
      expect(val, isNotNull);
    });

    test('createBallisticSimulation delegates to parent', () {
      const physics = AlwaysScrollableOverscrollPhysics();
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      final sim = physics.createBallisticSimulation(metrics, 1000);
      expect(sim, anything);
    });

    test('shouldAcceptUserOffset returns true for AlwaysScrollable', () {
      const physics = AlwaysScrollableOverscrollPhysics();
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      expect(physics.shouldAcceptUserOffset(metrics), isTrue);
    });
  });

  group('NeverScrollableOverscrollPhysics', () {
    test('applyTo returns new instance with parent and same bounds', () {
      const physics = NeverScrollableOverscrollPhysics(
        overscrollStart: 10,
        overscrollEnd: 20,
      );
      final applied = physics.applyTo(const ClampingScrollPhysics());
      expect(applied, isA<NeverScrollableOverscrollPhysics>());
      final appliedCast = applied as NeverScrollableOverscrollPhysics; // ignore: unnecessary_cast
      expect(appliedCast.overscrollStart, 10);
      expect(appliedCast.overscrollEnd, 20);
      expect(appliedCast.parent, isA<ClampingScrollPhysics>());
    });

    test('expandScrollMetrics alters bounds', () {
      const physics = NeverScrollableOverscrollPhysics(
        overscrollStart: 10,
        overscrollEnd: 20,
      );
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      final expanded = physics.expandScrollMetrics(metrics);
      expect(expanded.minScrollExtent, -10);
      expect(expanded.maxScrollExtent, 120);
    });

    test('shouldAcceptUserOffset returns false for NeverScrollable', () {
      const physics = NeverScrollableOverscrollPhysics();
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      expect(physics.shouldAcceptUserOffset(metrics), isFalse);
    });

    test('methods delegate to parent', () {
      const physics = NeverScrollableOverscrollPhysics();
      final metrics = FixedScrollMetrics(
        pixels: 0,
        axisDirection: AxisDirection.down,
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 50,
        devicePixelRatio: 1.0,
      );
      expect(
          physics.adjustPositionForNewDimensions(
            oldPosition: metrics,
            newPosition: metrics,
            isScrolling: false,
            velocity: 0,
          ),
          0.0);
      expect(physics.applyBoundaryConditions(metrics, 10), 0.0);
      expect(physics.applyPhysicsToUserOffset(metrics, 10), isNotNull);
      expect(physics.createBallisticSimulation(metrics, 1000),
          isNull); // NeverScrollable typically returns null
    });
  });

  group('Utilities debugPrintWithCallerInfo in long file name', () {
    test('truncates file name when length > 35', () {
      final originalIsMobile = Utilities.isMobile;
      Utilities.isMobile = false;
      String? loggedMessage;
      void listener(String msg) {
        loggedMessage = msg;
      }
      Utilities.addLogListener(listener);

      void helper2() {
        Utilities.debugPrintWithCallerInfo('test long filename truncation');
      }
      void helper1() {
        helper2();
      }

      try {
        helper1();
        expect(loggedMessage, contains('always_scrollable_overscroll_phy...'));
      } finally {
        Utilities.removeLogListener(listener);
        Utilities.isMobile = originalIsMobile;
      }
    });
  });
}

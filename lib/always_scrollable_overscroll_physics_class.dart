/// overscroll-physics.dart
///
/// Scrollphysics that allow overscrolling
///
/// Justin Hampton
/// 07/20/21
///
/// Adapted from
/// https://gist.github.com/makoConstruct/d069651b51d573a7a94bae13c8730656

import 'dart:math';

import 'package:flutter/material.dart';

class AlwaysScrollableOverscrollPhysics extends AlwaysScrollableScrollPhysics {
  final double overscrollStart;
  final double overscrollEnd;

  AlwaysScrollableOverscrollPhysics({
    this.overscrollStart = 0,
    this.overscrollEnd = 0,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  ScrollMetrics expandScrollMetrics(ScrollMetrics metrics) {
    return FixedScrollMetrics(
      pixels: metrics.pixels,
      axisDirection: metrics.axisDirection,
      minScrollExtent: min(metrics.minScrollExtent, -overscrollStart),
      maxScrollExtent: metrics.maxScrollExtent + overscrollEnd,
      viewportDimension: metrics.viewportDimension,
      devicePixelRatio: metrics.devicePixelRatio,
    );
  }

  @override
  AlwaysScrollableOverscrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AlwaysScrollableOverscrollPhysics(
      parent: buildParent(ancestor!)!,
      overscrollStart: overscrollStart,
      overscrollEnd: overscrollEnd,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(expandScrollMetrics(position), offset);
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return super.shouldAcceptUserOffset(expandScrollMetrics(position));
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    return super.adjustPositionForNewDimensions(
      oldPosition: expandScrollMetrics(oldPosition),
      newPosition: expandScrollMetrics(newPosition),
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return super.applyBoundaryConditions(
      expandScrollMetrics(position),
      value,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(expandScrollMetrics(position), velocity);
  }
}

class NeverScrollableOverscrollPhysics extends NeverScrollableScrollPhysics {
  final double overscrollStart;
  final double overscrollEnd;

  NeverScrollableOverscrollPhysics({
    this.overscrollStart = 0,
    this.overscrollEnd = 0,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  ScrollMetrics expandScrollMetrics(ScrollMetrics metrics) {
    return FixedScrollMetrics(
      pixels: metrics.pixels,
      axisDirection: metrics.axisDirection,
      minScrollExtent: min(metrics.minScrollExtent, -overscrollStart),
      maxScrollExtent: metrics.maxScrollExtent + overscrollEnd,
      viewportDimension: metrics.viewportDimension,
      devicePixelRatio: metrics.devicePixelRatio,
    );
  }

  @override
  NeverScrollableOverscrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NeverScrollableOverscrollPhysics(
      parent: buildParent(ancestor!)!,
      overscrollStart: overscrollStart,
      overscrollEnd: overscrollEnd,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(expandScrollMetrics(position), offset);
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return super.shouldAcceptUserOffset(expandScrollMetrics(position));
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    return super.adjustPositionForNewDimensions(
      oldPosition: expandScrollMetrics(oldPosition),
      newPosition: expandScrollMetrics(newPosition),
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return super.applyBoundaryConditions(
      expandScrollMetrics(position),
      value,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(expandScrollMetrics(position), velocity);
  }
}

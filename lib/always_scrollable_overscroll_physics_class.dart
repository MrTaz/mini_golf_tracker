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
  const AlwaysScrollableOverscrollPhysics({
    this.overscrollStart = 0,
    this.overscrollEnd = 0,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  final double overscrollEnd;
  final double overscrollStart;

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
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(expandScrollMetrics(position), offset);
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
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(expandScrollMetrics(position), velocity);
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return super.shouldAcceptUserOffset(expandScrollMetrics(position));
  }

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
}

class NeverScrollableOverscrollPhysics extends NeverScrollableScrollPhysics {
  const NeverScrollableOverscrollPhysics({
    this.overscrollStart = 0,
    this.overscrollEnd = 0,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  final double overscrollEnd;
  final double overscrollStart;

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
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(expandScrollMetrics(position), offset);
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
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return super.createBallisticSimulation(expandScrollMetrics(position), velocity);
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return super.shouldAcceptUserOffset(expandScrollMetrics(position));
  }

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
}

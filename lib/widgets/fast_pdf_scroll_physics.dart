import 'package:flutter/widgets.dart';

/// Faster vertical finger scrolling while keeping document edges clamped.
class FastPdfScrollPhysics extends ClampingScrollPhysics {
  const FastPdfScrollPhysics({this.speedMultiplier = 2.0, super.parent})
    : assert(speedMultiplier > 0 && speedMultiplier < double.infinity);

  final double speedMultiplier;

  @override
  FastPdfScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPdfScrollPhysics(
      speedMultiplier: speedMultiplier,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return super.createBallisticSimulation(
      position,
      position.axis == Axis.vertical ? velocity * speedMultiplier : velocity,
    );
  }
}

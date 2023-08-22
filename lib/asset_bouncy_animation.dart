import 'package:flutter/widgets.dart';

/// A Widget which makes its child bounce up and down.
class BouncyAnimation extends StatefulWidget {
  const BouncyAnimation(
      {this.duration = const Duration(seconds: 1),
      required this.lift,
      this.pause = 0,
      this.ratio = 0.25,
      required this.child,
      super.key});

  /// the Widget which will bounce
  final Widget child;

  /// total duration of the bounce cycle, including pause
  final Duration duration;

  /// how high to lift before dropping
  final double lift;

  /// ratio of the cycle which should be inactive (between 0 and 1)
  final double pause;

  /// ratio of lift to drop phases
  final double ratio;

  @override
  BouncyAnimationState createState() => BouncyAnimationState();
}

class BouncyAnimationState extends State<BouncyAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return _BouncyAnimation(
        controller: _controller, lift: widget.lift, pause: widget.pause, ratio: widget.ratio, child: widget.child);
  }
}

class _BouncyAnimation extends StatelessWidget {
  _BouncyAnimation({
    required this.controller,
    required this.lift,
    required this.pause,
    required this.ratio,
    required this.child,
  })  : upPhase = Tween<double>(begin: 0.0, end: lift).animate(
            CurvedAnimation(parent: controller, curve: Interval(0.0, ratio * (1 - pause), curve: Curves.decelerate))),
        downPhase = Tween<double>(begin: lift, end: 0).animate(CurvedAnimation(
            parent: controller, curve: Interval(ratio * (1 - pause), (1.0 - pause), curve: Curves.bounceOut))),
        pausePhase =
            Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: controller, curve: Interval(1 - pause, 1)));

  final Widget child;
  final AnimationController controller;
  final Animation<double> downPhase;
  final double lift;
  final double pause;
  final Animation<double> pausePhase;
  final double ratio;
  final Animation<double> upPhase;

  Widget _buildAnimation(BuildContext context, Widget? child) {
    Animation<double> phase = pausePhase;
    if (controller.value >= 0 && controller.value < (ratio * (1 - pause))) {
      phase = upPhase;
    }
    if (controller.value >= (ratio * (1 - pause)) && (controller.value < (1 - pause))) {
      phase = downPhase;
    }
    return Transform(transform: Matrix4.translationValues(0, -1 * phase.value, 0), child: child ?? const SizedBox());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: controller, builder: _buildAnimation, child: child);
  }
}

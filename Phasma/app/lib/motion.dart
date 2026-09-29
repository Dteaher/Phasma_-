import 'dart:math' as math;
import 'package:flutter/material.dart';

class MotionSettings extends InheritedWidget {
  final bool enabled;
  const MotionSettings({
    super.key,
    required this.enabled,
    required super.child,
  });
  static bool enabledOf(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<MotionSettings>()?.enabled ??
          true) &&
      !MediaQuery.disableAnimationsOf(context);
  @override
  bool updateShouldNotify(MotionSettings oldWidget) =>
      enabled != oldWidget.enabled;
}

/// Keeps a single live page: outgoing games cannot receive touches or retain timers.
class EnterMotion extends StatefulWidget {
  final Widget child;
  final Object? identity;
  final bool pop;
  const EnterMotion({
    super.key,
    required this.child,
    this.identity,
    this.pop = false,
  });
  @override
  State<EnterMotion> createState() => _EnterMotionState();
}

class _EnterMotionState extends State<EnterMotion>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  bool enabled = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    enabled = MotionSettings.enabledOf(context);
    if (!enabled) {
      controller.value = 1;
    } else if (controller.value == 0 && !controller.isAnimating) {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(EnterMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity && enabled) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (context, child) {
      final t = Curves.easeOutCubic.transform(controller.value);
      return Opacity(
        opacity: .35 + .65 * t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * (widget.pop ? 0 : 12)),
          child: Transform.scale(
            scale: widget.pop ? .92 + .08 * t : 1,
            child: child,
          ),
        ),
      );
    },
  );
}

class PressMotion extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const PressMotion({super.key, required this.child, this.enabled = true});
  @override
  State<PressMotion> createState() => _PressMotionState();
}

class _PressMotionState extends State<PressMotion> {
  bool down = false;
  void pressed(bool value) {
    if (mounted && down != value) setState(() => down = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => pressed(true) : null,
    onPointerUp: (_) => pressed(false),
    onPointerCancel: (_) => pressed(false),
    child: AnimatedScale(
      scale: down && widget.enabled ? .96 : 1,
      duration: MotionSettings.enabledOf(context)
          ? const Duration(milliseconds: 130)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class DreamProgress extends StatelessWidget {
  final double value, minHeight;
  final BorderRadius? borderRadius;
  final Color? backgroundColor, color;
  const DreamProgress({
    super.key,
    required this.value,
    this.minHeight = 10,
    this.borderRadius,
    this.backgroundColor,
    this.color,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: MotionSettings.enabledOf(context)
        ? const Duration(milliseconds: 500)
        : Duration.zero,
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      borderRadius: borderRadius ?? BorderRadius.circular(10),
      color: color,
      backgroundColor: backgroundColor,
    ),
  );
}

class RewardMotion extends StatefulWidget {
  final Widget child;
  final Object trigger;
  final bool playOnMount;
  const RewardMotion({
    super.key,
    required this.child,
    required this.trigger,
    this.playOnMount = false,
  });
  @override
  State<RewardMotion> createState() => _RewardMotionState();
}

class _RewardMotionState extends State<RewardMotion>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool enabled = true, initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    enabled = MotionSettings.enabledOf(context);
    if (!enabled) {
      controller.stop();
      controller.value = 1;
    }
    if (!initialized && widget.playOnMount && enabled) controller.forward();
    initialized = true;
  }

  @override
  void didUpdateWidget(RewardMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (enabled && oldWidget.trigger != widget.trigger) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (enabled)
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) =>
                    CustomPaint(painter: _ConfettiPainter(controller.value)),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    const colors = [
      Color(0xFFFFD247),
      Color(0xFFB597F4),
      Color(0xFF51CDA9),
      Color(0xFFFF8CB4),
    ];
    final opacity = (1 - progress).clamp(0.0, 1.0);
    for (var i = 0; i < 32; i++) {
      final fraction = i / 31;
      final x = size.width * fraction + math.sin(progress * 5 + i) * 20;
      final y = -25 + progress * (size.height * .75 + (i % 5) * 24);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 5 + i.toDouble());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: i.isEven ? 7 : 5,
            height: 11,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = colors[i % colors.length].withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

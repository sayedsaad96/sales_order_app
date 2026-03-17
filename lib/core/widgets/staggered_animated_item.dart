import 'package:flutter/material.dart';

class StaggeredAnimatedItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration itemDelay;
  final Duration animationDuration;
  final Offset startOffset;
  final Curve curve;

  const StaggeredAnimatedItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = Duration.zero,
    this.itemDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 500),
    this.startOffset = const Offset(0, 30), // 30 pixels down
    this.curve = Curves.easeOutQuart,
  });

  @override
  State<StaggeredAnimatedItem> createState() => _StaggeredAnimatedItemState();
}

class _StaggeredAnimatedItemState extends State<StaggeredAnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Map pixel offset to fractional offset based on assumed context if possible,
    // but Transform.translate uses logical pixels, so we just use the animation directly.
    _startAnimation();
  }

  void _startAnimation() async {
    final delay = widget.baseDelay + (widget.itemDelay * widget.index);
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate the current offset interpolation manually for translation
        final offsetValue =
            Offset.lerp(widget.startOffset, Offset.zero, _controller.value) ??
            Offset.zero;

        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(offset: offsetValue, child: child),
        );
      },
      child: widget.child,
    );
  }
}

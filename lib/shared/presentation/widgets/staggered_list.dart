import 'package:flutter/material.dart';

/// Animates children with a staggered slide + fade entrance.
/// Each child appears after a delay proportional to its index.
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration itemDelay;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 250),
    this.itemDelay = const Duration(milliseconds: 80),
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final totalMs = widget.itemDuration.inMilliseconds +
        (widget.children.length - 1) * widget.itemDelay.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs.clamp(1, 3000)),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.children.length, (i) {
        final startMs = i * widget.itemDelay.inMilliseconds;
        final endMs = startMs + widget.itemDuration.inMilliseconds;
        final begin = startMs / total;
        final end = (endMs / total).clamp(0.0, 1.0);

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}

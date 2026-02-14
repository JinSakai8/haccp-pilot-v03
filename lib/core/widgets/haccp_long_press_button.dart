
import 'dart:async';
import 'package:flutter/material.dart';

class HaccpLongPressButton extends StatefulWidget {
  final String label;
  final VoidCallback onCompleted;
  final Color color;
  final IconData? icon;
  final double height;
  final Duration requiredDuration;

  const HaccpLongPressButton({
    super.key,
    required this.label,
    required this.onCompleted,
    this.color = const Color(0xFF2E7D32), // Green default
    this.icon,
    this.height = 60.0,
    this.requiredDuration = const Duration(seconds: 1),
  });

  @override
  State<HaccpLongPressButton> createState() => _HaccpLongPressButtonState();
}

class _HaccpLongPressButtonState extends State<HaccpLongPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: widget.requiredDuration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
        _reset();
      }
    });
  }

  void _reset() {
    _controller.reset();
    _isPressed = false;
    if (mounted) setState(() {});
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Stack(
        children: [
          // Background container
          Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color, width: 2),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isPressed ? "PRZYTRZYMAJ..." : widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Progress overlay
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * _controller.value,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

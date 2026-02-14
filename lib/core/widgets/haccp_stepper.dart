
import 'dart:async';
import 'package:flutter/material.dart';

class HaccpStepper extends StatefulWidget {
  final double value;
  final double step;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String unit;
  final int decimalPlaces;

  const HaccpStepper({
    super.key,
    required this.value,
    this.step = 1.0,
    this.min = 0.0,
    this.max = 999.0,
    required this.onChanged,
    this.unit = '',
    this.decimalPlaces = 1,
  });

  @override
  State<HaccpStepper> createState() => _HaccpStepperState();
}

class _HaccpStepperState extends State<HaccpStepper> {
  Timer? _timer;

  void _increment() {
    if (widget.value + widget.step <= widget.max) {
      widget.onChanged(widget.value + widget.step);
    }
  }

  void _decrement() {
    if (widget.value - widget.step >= widget.min) {
      widget.onChanged(widget.value - widget.step);
    }
  }

  void _startAutoChange(VoidCallback callback) {
    _stopAutoChange(); // Safety
    callback();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      callback();
    });
  }

  void _stopAutoChange() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton(Icons.remove, _decrement),
          Column(
            children: [
              Text(
                '${widget.value.toStringAsFixed(widget.decimalPlaces)} ${widget.unit}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          _buildButton(Icons.add, _increment),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback action) {
    return GestureDetector(
      onTapDown: (_) => _startAutoChange(action),
      onTapUp: (_) => _stopAutoChange(),
      onTapCancel: _stopAutoChange,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}

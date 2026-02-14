import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';

class HaccpStepper extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  const HaccpStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 300,
    this.step = 1,
    this.unit = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: HaccpDesignTokens.minTouchTarget,
      decoration: BoxDecoration(
        color: HaccpDesignTokens.surface,
        borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          _buildButton(
            icon: Icons.remove,
            onPressed: value > min ? () => onChanged(value - step) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onPressed: value < max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
        child: Container(
          width: HaccpDesignTokens.minTouchTarget, // 60x60dp touch target
          height: HaccpDesignTokens.minTouchTarget,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 32,
            color: onPressed != null ? HaccpDesignTokens.primary : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

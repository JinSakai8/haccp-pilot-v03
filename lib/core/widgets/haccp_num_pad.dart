import 'package:flutter/material.dart';
import '../constants/design_tokens.dart';

class HaccpNumPad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final bool disabled;
  final List<String> extraKeys;
  final bool isPremiumGlass;

  const HaccpNumPad({
    super.key,
    required this.onDigitPressed,
    required this.onClear,
    required this.onBackspace,
    this.disabled = false,
    this.extraKeys = const [],
    this.isPremiumGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    // Standard numeric rows
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '←'],
    ];

    // If extra keys provided (e.g. ['/']), add them as a new row
    if (extraKeys.isNotEmpty) {
      rows.add(extraKeys);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((label) => _buildPadButton(label)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPadButton(String label) {
    final isAction = label == 'C' || label == '←';

    Color bgColor;
    Color fgColor;
    if (label == 'C') {
      bgColor = isPremiumGlass ? Colors.white.withValues(alpha: 0.1) : HaccpDesignTokens.error.withValues(alpha: 0.15);
      fgColor = isPremiumGlass ? const Color(0xFFE0E0E0) : HaccpDesignTokens.error;
    } else if (label == '←') {
      bgColor = isPremiumGlass ? Colors.white.withValues(alpha: 0.1) : HaccpDesignTokens.surface;
      fgColor = isPremiumGlass ? const Color(0xFFE0E0E0) : Colors.white70;
    } else {
      bgColor = isPremiumGlass ? Colors.white.withValues(alpha: 0.1) : HaccpDesignTokens.surface;
      fgColor = Colors.white;
    }

    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: disabled
            ? null
            : () {
                if (label == 'C') {
                  onClear();
                } else if (label == '←') {
                  onBackspace();
                } else {
                  // Standard digits + extra keys (like '/')
                  onDigitPressed(label);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
            side: isPremiumGlass ? BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0) : BorderSide.none,
          ),
          padding: EdgeInsets.zero,
          elevation: isPremiumGlass ? 0 : 2,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 22 : 28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

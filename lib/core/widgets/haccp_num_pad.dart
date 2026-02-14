import 'package:flutter/material.dart';
import '../constants/design_tokens.dart';

class HaccpNumPad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final bool disabled;

  const HaccpNumPad({
    super.key,
    required this.onDigitPressed,
    required this.onClear,
    required this.onBackspace,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '←'],
    ];

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
      bgColor = HaccpDesignTokens.error.withValues(alpha: 0.15);
      fgColor = HaccpDesignTokens.error;
    } else if (label == '←') {
      bgColor = HaccpDesignTokens.surface;
      fgColor = Colors.white70;
    } else {
      bgColor = HaccpDesignTokens.surface;
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
                  onDigitPressed(label);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
          ),
          padding: EdgeInsets.zero,
          elevation: 2,
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

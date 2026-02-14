import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';

class HaccpToggle extends StatelessWidget {
  final bool? value;
  final String positiveLabel;
  final String negativeLabel;
  final ValueChanged<bool?> onChanged;

  const HaccpToggle({
    super.key,
    required this.value,
    this.positiveLabel = 'OK',
    this.negativeLabel = 'PROBLEM',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleOption(
            label: negativeLabel,
            isSelected: value == false,
            activeColor: HaccpDesignTokens.error,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleOption(
            label: positiveLabel,
            isSelected: value == true,
            activeColor: HaccpDesignTokens.success,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: HaccpDesignTokens.minTouchTarget,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : HaccpDesignTokens.surface,
          borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
          border: isSelected ? null : Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

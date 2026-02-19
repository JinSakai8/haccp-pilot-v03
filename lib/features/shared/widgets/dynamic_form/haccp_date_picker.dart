import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import 'package:intl/intl.dart';

class HaccpDatePicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<String> onChanged; // Expects ISO string or formatted string depending on form logic?
  // DynamicForm usually stores string or dynamic. Let's assume ISO string for storage, but display formatted.
  
  const HaccpDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = value != null ? DateFormat('dd.MM.yyyy').format(value!) : 'Wybierz datę...';

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: HaccpDesignTokens.primary,
                  onPrimary: Colors.black,
                  surface: HaccpDesignTokens.surface,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          // Store as ISO Date (YYYY-MM-DD)
          onChanged(DateFormat('yyyy-MM-dd').format(picked));
        }
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: HaccpDesignTokens.surface,
          borderRadius: BorderRadius.circular(HaccpDesignTokens.inputRadius),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              displayDate,
              style: TextStyle(
                fontSize: 16,
                color: value == null ? Colors.white54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

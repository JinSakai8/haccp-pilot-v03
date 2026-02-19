import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';

class HaccpTimePicker extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<String> onChanged; // Expects "HH:mm"

  const HaccpTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayTime = value != null ? value!.format(context) : 'Wybierz godzinę...';

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
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
          // Format as HH:mm with leading zeros
          final hour = picked.hour.toString().padLeft(2, '0');
          final minute = picked.minute.toString().padLeft(2, '0');
          onChanged('$hour:$minute');
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
            const Icon(Icons.access_time, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              displayTime,
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

import 'package:flutter/material.dart';
import '../../core/constants/design_tokens.dart';

class HaccpTimePicker extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String label;

  const HaccpTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Godzina',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickTime(context),
          borderRadius: BorderRadius.circular(HaccpDesignTokens.radiusMedium),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(HaccpDesignTokens.radiusMedium),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null ? value!.format(context) : '--:--',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: value != null ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Icon(Icons.access_time, color: Colors.white54, size: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color(0xFF1E1E1E),
                hourMinuteTextColor: MaterialStateColor.resolveWith((states) =>
                    states.contains(MaterialState.selected)
                        ? Colors.black
                        : Colors.white),
                hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                    states.contains(MaterialState.selected)
                        ? HaccpDesignTokens.primary
                        : Colors.white10),
                dialHandColor: HaccpDesignTokens.primary,
                dialBackgroundColor: Colors.white10,
                entryModeIconColor: HaccpDesignTokens.primary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: HaccpDesignTokens.primary,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

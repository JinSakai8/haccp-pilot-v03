import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/design_tokens.dart';

class HaccpDatePicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const HaccpDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Data',
    this.firstDate,
    this.lastDate,
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
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null ? DateFormat('yyyy-MM-dd').format(value!) : '---- -- --',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: value != null ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Icon(Icons.calendar_today, color: Colors.white54, size: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: HaccpDesignTokens.primary,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

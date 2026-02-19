import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';

class HaccpTextInput extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hintText;
  final int maxLines;

  const HaccpTextInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hintText,
    this.maxLines = 3,
  });

  @override
  State<HaccpTextInput> createState() => _HaccpTextInputState();
}

class _HaccpTextInputState extends State<HaccpTextInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant HaccpTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HaccpDesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: HaccpDesignTokens.surface,
            borderRadius: BorderRadius.circular(HaccpDesignTokens.inputRadius), // Using the newly added token
            border: Border.all(
              color: HaccpDesignTokens.border,
            ),
          ),
          child: TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Wpisz treść...',
              hintStyle: const TextStyle(color: Colors.white30),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/haccp_num_pad.dart';

class HaccpNumPadInput extends StatefulWidget {
  final double? value;
  final ValueChanged<double> onChanged;
  final String label;
  final String suffix;
  final double? max;
  final int maxLength;

  const HaccpNumPadInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.suffix = '',
    this.max,
    this.maxLength = 6,
  });

  @override
  State<HaccpNumPadInput> createState() => _HaccpNumPadInputState();
}

class _HaccpNumPadInputState extends State<HaccpNumPadInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateText();
  }

  @override
  void didUpdateWidget(covariant HaccpNumPadInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateText();
    }
  }

  void _updateText() {
    if (widget.value == null) {
      _controller.text = '';
    } else {
      _controller.text = widget.value! % 1 == 0
          ? widget.value!.toInt().toString()
          : widget.value!.toString();
    }
  }

  void _showNumPad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HaccpDesignTokens.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _NumPadSheet(
          initialValue: _controller.text,
          maxLength: widget.maxLength,
          label: widget.label,
          max: widget.max,
          onConfirm: (val) {
            final doubleVal = double.tryParse(val);
            if (doubleVal != null) {
              widget.onChanged(doubleVal);
            }
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNumPad(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixText: widget.suffix,
            suffixIcon: const Icon(Icons.dialpad, color: HaccpDesignTokens.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
            ),
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _NumPadSheet extends StatefulWidget {
  final String initialValue;
  final int maxLength;
  final String label;
  final double? max;
  final ValueChanged<String> onConfirm;

  const _NumPadSheet({
    required this.initialValue,
    required this.maxLength,
    required this.label,
    this.max,
    required this.onConfirm,
  });

  @override
  State<_NumPadSheet> createState() => _NumPadSheetState();
}

class _NumPadSheetState extends State<_NumPadSheet> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _onDigit(String digit) {
    if (_currentValue.length >= widget.maxLength) return;
    // Simple decimal check
    if (digit == '.' && _currentValue.contains('.')) return;
    
    setState(() {
      _currentValue += digit;
    });
  }

  void _onBackspace() {
    if (_currentValue.isNotEmpty) {
      setState(() {
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _currentValue = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HaccpDesignTokens.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HaccpDesignTokens.primary),
              ),
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: Text(
                _currentValue.isEmpty ? '0' : _currentValue,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            HaccpNumPad(
              onDigitPressed: _onDigit, 
              onClear: _onClear, 
              onBackspace: _onBackspace,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => widget.onConfirm(_currentValue),
                style: ElevatedButton.styleFrom(backgroundColor: HaccpDesignTokens.primary),
                child: const Text('ZATWIERDŹ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

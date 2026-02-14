import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/haccp_num_pad.dart';

class HaccpNumPadInput extends StatefulWidget {
  final double? value;
  final ValueChanged<double>? onChanged;
  final String? textValue;
  final ValueChanged<String>? onTextChanged;
  final String label;
  final String suffix;
  final double? max;
  final int maxLength;
  final List<String> extraKeys;

  const HaccpNumPadInput({
    super.key,
    this.value,
    this.onChanged,
    required this.label,
    this.suffix = '',
    this.max,
    this.maxLength = 6,
    this.textValue,
    this.onTextChanged,
    this.extraKeys = const [],
  }) : assert(onChanged != null || onTextChanged != null, 'Must provide either onChanged (double) or onTextChanged (String)');

  @override
  State<HaccpNumPadInput> createState() => _HaccpNumPadInputState();
}

class _HaccpNumPadInputState extends State<HaccpNumPadInput> {
  final TextEditingController _controller = TextEditingController();

  bool get _isStringMode => widget.onTextChanged != null;

  @override
  void initState() {
    super.initState();
    _updateText();
  }

  @override
  void didUpdateWidget(covariant HaccpNumPadInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isStringMode) {
      if (oldWidget.textValue != widget.textValue) _updateText();
    } else {
      if (oldWidget.value != widget.value) _updateText();
    }
  }

  void _updateText() {
    if (_isStringMode) {
       _controller.text = widget.textValue ?? '';
    } else {
      if (widget.value == null) {
        _controller.text = '';
      } else {
        _controller.text = widget.value! % 1 == 0
            ? widget.value!.toInt().toString()
            : widget.value!.toString();
      }
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
          extraKeys: widget.extraKeys,
          isStringMode: _isStringMode,
          onConfirm: (val) {
            if (_isStringMode) {
              widget.onTextChanged?.call(val);
            } else {
              final doubleVal = double.tryParse(val.replaceAll(',', '.'));
              if (doubleVal != null) {
                widget.onChanged?.call(doubleVal);
              }
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
  final List<String> extraKeys;
  final bool isStringMode;
  final ValueChanged<String> onConfirm;

  const _NumPadSheet({
    required this.initialValue,
    required this.maxLength,
    required this.label,
    this.max,
    required this.onConfirm,
    this.extraKeys = const [],
    this.isStringMode = false,
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
    
    // Decimal check only for numeric mode
    if (!widget.isStringMode) {
       if ((digit == '.' || digit == ',') && (_currentValue.contains('.') || _currentValue.contains(','))) return;
    }
    
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
                _currentValue.isEmpty ? ' ' : _currentValue,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            HaccpNumPad(
              onDigitPressed: _onDigit, 
              onClear: _onClear, 
              onBackspace: _onBackspace,
              extraKeys: widget.extraKeys,
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

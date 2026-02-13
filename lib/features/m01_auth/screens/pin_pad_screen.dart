import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/providers/auth_provider.dart';

/// Ekran 1.2 — PIN Pad
/// Stitch ID: ea93036fd47e47ee983a97411bbee99a
///
/// Glove-Friendly numeric keypad (80×80dp buttons), 4-dot PIN display,
/// auto-submit at 4 digits, error banner with 3s auto-hide.
class PinPadScreen extends ConsumerStatefulWidget {
  const PinPadScreen({super.key});

  @override
  ConsumerState<PinPadScreen> createState() => _PinPadScreenState();
}

class _PinPadScreenState extends ConsumerState<PinPadScreen> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);

    // Auto-submit when 4 digits entered
    if (_pin.length == 4) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onClear() {
    setState(() => _pin = '');
  }

  Future<void> _submit() async {
    final notifier = ref.read(pinLoginProvider.notifier);
    final employee = await notifier.login(_pin);

    if (!mounted) return;

    if (employee != null) {
      context.go('/zone-select');
    } else {
      // Reset PIN field on error (error banner handled by provider)
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginStatus = ref.watch(pinLoginProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // ── Logo area ──
            const Icon(
              Icons.verified_user,
              size: 48,
              color: HaccpDesignTokens.primary,
            ),
            const SizedBox(height: 8),
            const Text(
              'HACCP Pilot • Logowanie',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const Spacer(),

            // ── PIN dots (4 circles) ──
            _buildPinDots(),
            const SizedBox(height: 24),

            // ── Error banner ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: loginStatus == LoginStatus.error
                  ? Container(
                      key: const ValueKey('error'),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: HaccpDesignTokens.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          HaccpDesignTokens.cardRadius,
                        ),
                        border: Border.all(color: HaccpDesignTokens.error),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: HaccpDesignTokens.error, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'BŁĘDNY PIN',
                            style: TextStyle(
                              color: HaccpDesignTokens.error,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),

            // ── Loading indicator ──
            if (loginStatus == LoginStatus.loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(
                  color: HaccpDesignTokens.primary,
                ),
              ),

            const Spacer(),

            // ── Numeric keypad ──
            _buildNumPad(loginStatus == LoginStatus.loading),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── PIN Dots Row ──
  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: filled ? 28 : 24,
          height: filled ? 28 : 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? HaccpDesignTokens.primary : Colors.transparent,
            border: Border.all(
              color: HaccpDesignTokens.primary,
              width: 2.5,
            ),
          ),
        );
      }),
    );
  }

  // ── NumPad Grid (3×4, 80×80dp buttons — Glove-Friendly) ──
  Widget _buildNumPad(bool disabled) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '←'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map((label) => _buildPadButton(label, disabled))
                  .toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPadButton(String label, bool disabled) {
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
                  _onClear();
                } else if (label == '←') {
                  _onBackspace();
                } else {
                  _onDigit(label);
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
          elevation: 0,
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

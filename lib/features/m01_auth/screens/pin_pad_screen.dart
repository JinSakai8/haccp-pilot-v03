import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/haccp_num_pad.dart';

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
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    
    // Block input if locked
    final status = ref.read(pinLoginProvider);
    if (status == LoginStatus.locked) return;

    setState(() => _pin += digit);

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
      // Reset PIN field on error
      setState(() => _pin = '');
    }
  }

  String _getLockoutTimeRemaining() {
    final notifier = ref.read(pinLoginProvider.notifier);
    final lockoutUntil = notifier.lockoutUntil;
    if (lockoutUntil == null) return '';
    
    final remaining = lockoutUntil.difference(DateTime.now());
    if (remaining.isNegative) return '';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loginStatus = ref.watch(pinLoginProvider);
    final isLocked = loginStatus == LoginStatus.locked;

    // Timer logic for UI updates
    if (isLocked) {
      if (_lockoutTimer == null || !_lockoutTimer!.isActive) {
        _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {}); 
        });
      }
    } else {
      _lockoutTimer?.cancel();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Premium Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark moody gradient overlay for elegance and text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
            const SizedBox(height: 40),

            // ── Logo area ──
            const Icon(
              Icons.restaurant_menu, // Bardziej fine-dining icon
              size: 56,
              color: Color(0xFFD4AF37), // Luksusowe złoto / miedź
            ),
            const SizedBox(height: 12),
            const Text(
              'MIĘSO I PIANA',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Work Sans',
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'HACCP System',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),

            const Spacer(),

            // ── PIN dots (4 circles) ──
            _buildPinDots(),
            const SizedBox(height: 24),

            // ── Error / Lockout banner ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLocked 
                  ? Container(
                      key: const ValueKey('locked'),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: HaccpDesignTokens.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
                        border: Border.all(color: HaccpDesignTokens.error),
                      ),
                      child: Column(
                        children: [
                           const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_clock, color: HaccpDesignTokens.error, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'BLOKADA',
                                style: TextStyle(
                                  color: HaccpDesignTokens.error,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spróbuj za: ${_getLockoutTimeRemaining()}',
                            style: const TextStyle(
                              color: HaccpDesignTokens.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : loginStatus == LoginStatus.error
                      ? Container(
                          key: const ValueKey('error'),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: HaccpDesignTokens.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
                            border: Border.all(color: HaccpDesignTokens.error),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: HaccpDesignTokens.error, size: 28),
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
                      : const SizedBox(height: 56 + 28), // Placeholder height
            ),

            // ── Loading indicator ──
            if (loginStatus == LoginStatus.loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(color: HaccpDesignTokens.primary),
              ),

            const Spacer(),

            // ── Numeric keypad in Glassmorphism Card ──
            ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                  child: HaccpNumPad(
                    disabled: loginStatus == LoginStatus.loading || isLocked,
                    onDigitPressed: _onDigit,
                    onClear: _onClear,
                    onBackspace: _onBackspace,
                    isPremiumGlass: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ], // end of Stack children
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
            color: filled ? const Color(0xFFD4AF37) : Colors.transparent, // Gold
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 2.5,
            ),
          ),
        );
      }),
    );
  }
}

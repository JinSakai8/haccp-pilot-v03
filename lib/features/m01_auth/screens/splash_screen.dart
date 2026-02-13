import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';

/// Ekran 1.1 — Splash / Branding
/// Stitch ID: bb89b45a89314b9a8899bcbc5e4354a3
///
/// Ciemny gradient, logo, nazwa, auto-redirect do PIN Pad po 2s.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Auto-navigate after 2 seconds (spec: auto-transition, no user interaction)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF222222), // Charcoal
              Color(0xFF121212), // Onyx
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Main Content ──
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo placeholder (shield + checkmark)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HaccpDesignTokens.primary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: HaccpDesignTokens.primary,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 60,
                        color: HaccpDesignTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Title
                    const Text(
                      'HACCP Pilot',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Venue Subtitle
                    const Text(
                      'Mięso i Piana',
                      style: TextStyle(
                        fontSize: 18,
                        color: HaccpDesignTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: HaccpDesignTokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Version badge — bottom right ──
            const Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                'v03-00',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/models/zone.dart';
import '../../../core/providers/auth_provider.dart';

/// Ekran 1.3 — Wybór Strefy
/// Stitch ID: b208b776aee94143a96231a3095c553c
///
/// Wyświetla strefy przypisane do zalogowanego pracownika.
/// Auto-select jeśli 1 strefa. Back -> PIN Pad.
class ZoneSelectionScreen extends ConsumerWidget {
  const ZoneSelectionScreen({super.key});

  static const _zoneIcons = <String, IconData>{
    'kuchnia': Icons.local_fire_department,
    'mroźnia': Icons.ac_unit,
    'magazyn': Icons.warehouse,
    'bar': Icons.local_bar,
    'sala': Icons.restaurant,
    'zmywak': Icons.cleaning_services,
  };

  IconData _iconForZone(String name) {
    final lower = name.toLowerCase();
    for (final entry in _zoneIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.kitchen;
  }

  Future<void> _activateZone(
    BuildContext context,
    WidgetRef ref, {
    required String employeeId,
    required String zoneId,
    required Zone zone,
  }) async {
    try {
      await ref.read(authRepositoryProvider).setKioskContext(
            employeeId: employeeId,
            zoneId: zoneId,
          );
      ref.read(currentZoneProvider.notifier).set(zone);
      if (context.mounted) {
        context.go('/hub');
      }
    } catch (e) {
      if (!context.mounted) return;
      final errorText = e.toString();
      final isSessionError = errorText.contains('auth.uid() is null') ||
          errorText.contains('Brak sesji Supabase Auth');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSessionError
                ? 'Brak sesji logowania. Odswiez aplikacje i sprobuj ponownie.'
                : 'Nie mozna ustawic kontekstu kiosku: $e',
          ),
          backgroundColor: HaccpDesignTokens.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentUserProvider);
    final zonesAsync = ref.watch(employeeZonesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  // Back to PIN Pad
                  IconButton(
                    onPressed: () async {
                      try {
                        await ref.read(authRepositoryProvider).clearKioskContext();
                      } catch (_) {
                        // Non-fatal: local state reset still proceeds.
                      }
                      ref.read(currentUserProvider.notifier).clear();
                      ref.read(pinLoginProvider.notifier).reset();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 28),
                    constraints: const BoxConstraints(
                      minWidth: HaccpDesignTokens.minTouchTarget,
                      minHeight: HaccpDesignTokens.minTouchTarget,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Wybierz Strefę',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Welcome message ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Text(
                'Zalogowano jako: ${employee?.fullName ?? "—"}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'Gdzie zaczynasz pracę?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white38,
                ),
              ),
            ),

            // ── Zone grid ──
            Expanded(
              child: zonesAsync.when(
                data: (zones) {
                  // Auto-select if only one zone
                  if (zones.length == 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final emp = ref.read(currentUserProvider);
                      if (emp == null) return;
                      _activateZone(
                        context,
                        ref,
                        employeeId: emp.id,
                        zoneId: zones.first.id,
                        zone: zones.first,
                      );
                    });
                    return const Center(
                      child: CircularProgressIndicator(
                        color: HaccpDesignTokens.primary,
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: zones.length,
                    itemBuilder: (context, index) {
                      final zone = zones[index];
                      return _ZoneTile(
                        name: zone.name,
                        icon: _iconForZone(zone.name),
                        onTap: () async {
                          final emp = ref.read(currentUserProvider);
                          if (emp == null) return;
                          await _activateZone(
                            context,
                            ref,
                            employeeId: emp.id,
                            zoneId: zone.id,
                            zone: zone,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: HaccpDesignTokens.primary,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: HaccpDesignTokens.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Błąd ładowania stref:\n$error',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: HaccpDesignTokens.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glove-Friendly zone tile (min 60×60dp).
class _ZoneTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  const _ZoneTile({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HaccpDesignTokens.surface,
      borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: HaccpDesignTokens.primary),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

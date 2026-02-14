import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/haccp_tile.dart';
import '../../../../core/constants/design_tokens.dart';
import '../providers/hr_provider.dart';

class HrDashboardScreen extends ConsumerWidget {
  const HrDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(hrEmployeesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HaccpTopBar(
              title: 'HR & Personel',
              onBackPressed: () => context.go('/hub'), // Back to Hub
              actions: [
                 IconButton(
                  icon: const Icon(Icons.list, size: 32),
                  onPressed: () => context.push('/hr/list'),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, size: 32),
                  onPressed: () => context.push('/hr/add'),
                ),
              ],
            ),
            
            Expanded(
              child: employeesAsync.when(
                data: (employees) {
                  final now = DateTime.now();
                  final expiredCount = employees.where((e) => 
                    e.sanepidExpiry != null && e.sanepidExpiry!.isBefore(now)).length;
                    
                  final expiringCount = employees.where((e) =>
                    e.sanepidExpiry != null && 
                    e.sanepidExpiry!.isAfter(now) &&
                    e.sanepidExpiry!.isBefore(now.add(const Duration(days: 30)))).length;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Alerts Section
                      if (expiredCount > 0)
                        _buildAlertCard(
                          context, 
                          'Przeterminowane Badania', 
                          '$expiredCount pracownik(ów)', 
                          DesignTokens.errorColor,
                          Icons.warning_rounded,
                        ),
                      if (expiringCount > 0)
                        _buildAlertCard(
                          context, 
                          'Wygasające Badania (30 dni)', 
                          '$expiringCount pracownik(ów)', 
                          DesignTokens.warningColor,
                          Icons.priority_high_rounded,
                        ),
                        
                      const SizedBox(height: 24),
                      Text('Szybkie Akcje', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: HaccpTile(
                              icon: Icons.people,
                              label: 'Lista Pracowników',
                              onTap: () => context.push('/hr/list'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: HaccpTile(
                              icon: Icons.person_add,
                              label: 'Dodaj Pracownika',
                              onTap: () => context.push('/hr/add'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Błąd: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, String title, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/hr/list'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              elevation: 0,
            ),
            child: const Text('ZOBACZ'),
          ),
        ],
      ),
    );
  }
}

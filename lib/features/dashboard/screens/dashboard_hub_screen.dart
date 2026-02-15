import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../../core/widgets/haccp_tile.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/dashboard_badges_provider.dart';

class DashboardHubScreen extends ConsumerWidget {
  const DashboardHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentUserProvider);
    final zone = ref.watch(currentZoneProvider);
    final badgesAsync = ref.watch(dashboardBadgesProvider);
    final badges = badgesAsync.value ?? {};

    final userName = employee?.fullName ?? '...';
    final venueName = zone?.name ?? '...';
    final isManager = employee?.isManager ?? false;

    return Scaffold(
      appBar: HaccpTopBar(
        title: "$venueName - $userName",
        showLogout: true,
      ),
      body: Column(
        children: [
          const HaccpOfflineBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid: 2 columns on mobile, 4 on tablet/desktop
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      // 1. Monitoring Temperatur
                      HaccpTile(
                        icon: Icons.thermostat,
                        label: 'Monitoring Temperatur',
                        badgeText: badges['monitoring'],
                        onTap: () => context.push(RouteNames.monitoring),
                      ),
                      // 2. Procesy GMP
                      HaccpTile(
                        icon: Icons.soup_kitchen, // meat/cooking icon
                        label: 'Procesy GMP',
                        badgeText: badges['gmp'],
                        onTap: () => context.push(RouteNames.gmp),
                      ),
                      // 3. Higiena GHP
                      HaccpTile(
                        icon: Icons.cleaning_services,
                        label: 'Higiena GHP',
                        badgeText: badges['ghp'],
                        onTap: () => context.push('/ghp'),
                      ),
                      // 4. Odpady BDO
                      HaccpTile(
                        icon: Icons.recycling,
                        label: 'Odpady BDO',
                        badgeText: badges['waste'],
                        onTap: () => context.push('/waste'),
                      ),
                       // 5. Raporty
                      HaccpTile(
                        icon: Icons.bar_chart,
                        label: 'Raporty',
                        badgeText: badges['reports'],
                        onTap: () => context.push('/reports'),
                      ),
                       // 6. HR (Manager only)
                      HaccpTile(
                        icon: Icons.people,
                        label: 'HR & Personel',
                        badgeText: badges['hr'],
                        isVisible: isManager,
                        onTap: () => context.push('/hr'),
                      ),
                       // 7. Ustawienia (Manager only)
                      HaccpTile(
                        icon: Icons.settings,
                        label: 'Ustawienia',
                        isVisible: isManager,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

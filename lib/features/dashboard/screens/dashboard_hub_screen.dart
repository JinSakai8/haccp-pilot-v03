import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/core/widgets/haccp_tile.dart';
import 'package:haccp_pilot/core/router/route_names.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';

class DashboardHubScreen extends ConsumerWidget {
  const DashboardHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In future: ref.watch(userProvider) to get name/venue
    final userName = "Jan Kowalski"; // Placeholder
    final venueName = "Kuchnia Główna"; // Placeholder

    return Scaffold(
      appBar: HaccpTopBar(
        title: "$venueName - $userName",
        showLogout: true,
      ),
      body: Padding(
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
                  badgeText: null, // Dynamic in future
                  onTap: () => context.push(RouteNames.monitoring),
                ),
                // 2. Procesy GMP
                HaccpTile(
                  icon: Icons.soup_kitchen, // meat/cooking icon
                  label: 'Procesy GMP',
                  badgeText: null,
                  onTap: () => context.push(RouteNames.gmp),
                ),
                // 3. Higiena GHP
                HaccpTile(
                  icon: Icons.cleaning_services,
                  label: 'Higiena GHP',
                  onTap: () {}, // TODO
                ),
                // 4. Odpady BDO
                HaccpTile(
                  icon: Icons.recycling,
                  label: 'Odpady BDO',
                  onTap: () {}, // TODO
                ),
                 // 5. Raporty
                HaccpTile(
                  icon: Icons.bar_chart,
                  label: 'Raporty',
                  onTap: () {}, // TODO
                ),
                 // 6. HR (Manager only)
                HaccpTile(
                  icon: Icons.people,
                  label: 'HR & Personel',
                  isVisible: true, // Check role in future
                  onTap: () {}, // TODO
                ),
                 // 7. Ustawienia (Manager only)
                HaccpTile(
                  icon: Icons.settings,
                  label: 'Ustawienia',
                  isVisible: true, // Check role in future
                  onTap: () {}, // TODO
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

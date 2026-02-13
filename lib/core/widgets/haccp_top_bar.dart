import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:haccp_pilot/core/theme/app_theme.dart'; // Not needed if using Theme.of(context)
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/router/route_names.dart';

class HaccpTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;
  final List<Widget>? actions;

  const HaccpTopBar({
    super.key,
    required this.title,
    this.showLogout = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        if (actions != null) ...actions!,
        if (showLogout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                 // Simple logout logic: clear global state
                 ref.read(currentEmployeeProvider.notifier).clear();
                 ref.read(currentZoneProvider.notifier).clear();
                 
                 if (context.mounted) {
                   context.go(RouteNames.login);
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('WYLOGUJ'),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

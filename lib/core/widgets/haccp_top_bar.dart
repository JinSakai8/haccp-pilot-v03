import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/m01_auth/providers/auth_provider.dart';
import '../providers/auth_provider.dart';
import '../router/route_names.dart';
import '../services/connectivity_service.dart';
import '../constants/design_tokens.dart';

class HaccpTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const HaccpTopBar({
    super.key,
    required this.title,
    this.showLogout = false,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(connectivityProvider);
    final isOnline = isOnlineAsync.value ?? true; // Optimistic default

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.cloud_off,
                color: DesignTokens.errorColor,
                size: 20,
              ),
            ),
          Text(title),
        ],
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            )
          : null,
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

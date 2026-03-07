import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/design_tokens.dart';
import '../providers/connectivity_provider.dart';

class HaccpOfflineBanner extends ConsumerWidget {
  const HaccpOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (!isOnline) {
      return Container(
        width: double.infinity,
        color: HaccpDesignTokens.error,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Brak połączenia z internetem - praca w trybie offline',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

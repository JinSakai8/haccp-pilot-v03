import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../../core/widgets/haccp_tile.dart';

class GmpProcessSelectorScreen extends StatelessWidget {
  const GmpProcessSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Procesy GMP'),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          HaccpTile(
            icon: Icons.outdoor_grill,
            label: 'Pieczenie Mięs',
            onTap: () => context.push('/gmp/roasting'),
          ),
          HaccpTile(
            icon: Icons.ac_unit,
            label: 'Chłodzenie Żywności',
            onTap: () => context.push('/gmp/cooling'),
          ),
          HaccpTile(
            icon: Icons.local_shipping,
            label: 'Kontrola Dostaw',
            onTap: () => context.push('/gmp/delivery'),
          ),
          HaccpTile(
            icon: Icons.history,
            label: 'Historia Wpisów',
            onTap: () => context.push('/gmp/history'),
          ),
        ],
      ),
    );
  }
}

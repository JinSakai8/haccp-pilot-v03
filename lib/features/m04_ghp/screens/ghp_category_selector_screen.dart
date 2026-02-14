import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/haccp_tile.dart';

class GhpCategorySelectorScreen extends StatelessWidget {
  const GhpCategorySelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Higiena GHP'),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          HaccpTile(
            icon: Icons.person_outline,
            label: 'Personel',
            onTap: () => context.push('/ghp/checklist', extra: 'personnel'),
            color: Colors.blue,
          ),
          HaccpTile(
            icon: Icons.cleaning_services,
            label: 'Pomieszczenia',
            onTap: () => context.push('/ghp/checklist', extra: 'rooms'),
            color: Colors.green,
          ),
          HaccpTile(
            icon: Icons.build,
            label: 'Konserwacja',
            onTap: () => context.push('/ghp/checklist', extra: 'maintenance'),
            color: Colors.orange,
          ),
          HaccpTile(
            icon: Icons.science,
            label: 'Środki Czystości',
            onTap: () => context.push('/ghp/checklist', extra: 'chemicals'),
            color: Colors.purple,
          ),
           HaccpTile(
            icon: Icons.history,
            label: 'Historia',
            onTap: () => {}, // Placeholder for now
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

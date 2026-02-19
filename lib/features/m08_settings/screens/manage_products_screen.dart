import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/shared/repositories/products_repository.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _types = ['cooling', 'roasting', 'general'];
  final _labels = ['Chłodzenie', 'Obróbka Termiczna', 'Ogólne'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Zarządzanie Produktami'),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.onSurfaceVariant,
              indicatorColor: AppTheme.primary,
              tabs: _labels.map((l) => Tab(text: l)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _types.map((type) => _ProductList(type: type)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.onPrimary),
        onPressed: () => _showEditor(null, _types[_tabController.index]),
      ),
    );
  }

  void _showEditor(Product? product, String initialType) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(
        product: product, 
        initialType: initialType,
        onSave: (name, type) async {
           final repo = ref.read(productsRepositoryProvider);
           final zones = await ref.read(employeeZonesProvider.future);
           final venueId = zones.isNotEmpty ? zones.first.venueId : null; // Validation needed?

           if (venueId == null) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Błąd: Brak przypisanego lokalu')));
              return;
           }

           try {
             if (product == null) {
               await repo.addProduct(name: name, type: type, venueId: venueId);
             } else {
               await repo.updateProduct(id: product.id, name: name, type: type);
             }
             // Refresh provider
             ref.invalidate(productsProvider(type));
             if (product != null && product.type != type) {
               ref.invalidate(productsProvider(product.type)); // Refresh old type if changed
             }
           } catch (e) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
           }
        }
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  final String type;

  const _ProductList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(type));

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('Brak produktów w tej kategorii', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_,__) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final product = products[index];
            return Dismissible(
              key: ValueKey(product.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: AppTheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog(
                  context: context, 
                  builder: (ctx) => AlertDialog(
                    title: const Text('Usunąć produkt?'),
                    content: Text('Czy na pewno chcesz usunąć "${product.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń', style: TextStyle(color: Colors.red))),
                    ],
                  )
                );
              },
              onDismissed: (_) async {
                 await ref.read(productsRepositoryProvider).deleteProduct(product.id);
                 ref.invalidate(productsProvider(type));
              },
              child: Card(
                color: AppTheme.surface,
                child: ListTile(
                  title: Text(product.name, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () {
                     // Find parent to call _showEditor? Or use context traversal? 
                     // Riverpod approach: pass callback?
                     // Simplest: access State? No.
                     // Just use showDialog here again :) Reuse widget.
                     context.findAncestorStateOfType<_ManageProductsScreenState>()?._showEditor(product, type);
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,__) => Center(child: Text('Błąd: $e', style: const TextStyle(color: AppTheme.error))),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  final String initialType;
  final Function(String name, String type) onSave;

  const _ProductDialog({this.product, required this.initialType, required this.onSave});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late TextEditingController _nameCtrl;
  late String _type;
  final _types = {'cooling': 'Chłodzenie', 'roasting': 'Obróbka Termiczna', 'general': 'Ogólne'};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _type = widget.product?.type ?? widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Nowy Produkt' : 'Edycja Produktu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nazwa Produktu'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) => setState(() => _type = val!),
            decoration: const InputDecoration(labelText: 'Typ'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isNotEmpty) {
              widget.onSave(_nameCtrl.text, _type);
              Navigator.pop(context);
            }
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}

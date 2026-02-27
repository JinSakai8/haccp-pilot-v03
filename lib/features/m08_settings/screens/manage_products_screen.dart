import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/empty_state_widget.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/shared/repositories/products_repository.dart';

String mapProductErrorMessage(Object error) {
  final raw = error.toString().toLowerCase();

  if (raw.contains('products_name_venue_unique')) {
    return 'Produkt o tej nazwie juz istnieje w tej kategorii.';
  }
  if (raw.contains('row-level security') || raw.contains('permission denied')) {
    return 'Brak uprawnien do modyfikacji produktow.';
  }
  if (raw.contains('not in kiosk scope')) {
    return 'Produkt jest poza zakresem aktualnego lokalu.';
  }

  return 'Nie udalo sie zapisac zmian produktu.';
}

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() =>
      _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _types = ['cooling', 'roasting', 'general', 'rooms'];
  final _labels = ['Chlodzenie', 'Obrobka Termiczna', 'Ogolne', 'Pomieszczenia'];

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
      appBar: const HaccpTopBar(title: 'Zarzadzanie Produktami'),
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
          final venueId = ref.read(currentZoneProvider)?.venueId;

          if (venueId == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Brak przypisanego lokalu.')),
              );
            }
            return;
          }

          final normalizedName = name.trim();
          if (normalizedName.length < 2) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nazwa produktu jest za krotka.')),
              );
            }
            return;
          }

          try {
            final existing = await repo.getProducts(type, venueId: venueId);
            final duplicate = existing.any((p) {
              final sameName =
                  p.name.trim().toLowerCase() == normalizedName.toLowerCase();
              final differentEntity = product == null || p.id != product.id;
              return sameName && differentEntity;
            });

            if (duplicate) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Produkt o tej nazwie juz istnieje w tej kategorii.',
                    ),
                  ),
                );
              }
              return;
            }

            if (product == null) {
              await repo.addProduct(
                name: normalizedName,
                type: type,
                venueId: venueId,
              );
            } else {
              await repo.updateProduct(
                id: product.id,
                name: normalizedName,
                type: type,
              );
            }

            ref.invalidate(productsProvider(type));
            if (product != null && product.type != type) {
              ref.invalidate(productsProvider(product.type));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(mapProductErrorMessage(e))),
              );
            }
          }
        },
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
          return const HaccpEmptyState(
            headline: 'Brak produktow',
            subtext: 'Dodaj pierwszy produkt w tej kategorii.',
            icon: Icons.inventory_2_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                final decision = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Usunac produkt?'),
                    content: Text(
                      'Czy na pewno chcesz usunac "${product.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Anuluj'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Usun',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                return decision ?? false;
              },
              onDismissed: (_) async {
                try {
                  await ref
                      .read(productsRepositoryProvider)
                      .deleteProduct(product.id);
                  ref.invalidate(productsProvider(type));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(mapProductErrorMessage(e))),
                    );
                  }
                }
              },
              child: Card(
                color: AppTheme.surface,
                child: ListTile(
                  title: Text(
                    product.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () {
                    context
                        .findAncestorStateOfType<_ManageProductsScreenState>()
                        ?._showEditor(product, type);
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          mapProductErrorMessage(e),
          style: const TextStyle(color: AppTheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  final String initialType;
  final Future<void> Function(String name, String type) onSave;

  const _ProductDialog({
    this.product,
    required this.initialType,
    required this.onSave,
  });

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late TextEditingController _nameCtrl;
  late String _type;

  final _types = {
    'cooling': 'Chlodzenie',
    'roasting': 'Obrobka Termiczna',
    'general': 'Ogolne',
    'rooms': 'Pomieszczenia',
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _type = widget.product?.type ?? widget.initialType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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
            initialValue: _type,
            items: _types.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _type = val);
              }
            },
            decoration: const InputDecoration(labelText: 'Typ'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) {
              return;
            }
            await widget.onSave(name, _type);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}

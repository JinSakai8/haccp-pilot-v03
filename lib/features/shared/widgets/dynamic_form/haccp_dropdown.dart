import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../m07_hr/providers/hr_provider.dart';
import '../../repositories/products_repository.dart';

class _DropdownOption {
  final String id;
  final String label;

  const _DropdownOption({required this.id, required this.label});
}

class HaccpDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String>? staticOptions;
  final String? source;
  final String? sourceType;

  const HaccpDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.staticOptions,
    this.source,
    this.sourceType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (source == 'products_table') {
      final productsAsync = ref.watch(productsProvider(sourceType ?? 'general'));
      return productsAsync.when(
        data: (products) {
          final options = products
              .map((p) => _DropdownOption(id: p.id, label: p.name))
              .toList();
          return _buildDropdown(context, options);
        },
        loading: _buildLoading,
        error: (err, _) => _buildError('Blad ladowania: $err'),
      );
    }

    if (source == 'employees_table') {
      final employeesAsync = ref.watch(hrEmployeesProvider);
      final currentZone = ref.watch(currentZoneProvider);
      return employeesAsync.when(
        data: (employees) {
          final options = employees
              .where((e) {
                if (!e.isActive) return false;
                if (currentZone == null) return true;
                if (e.zones.isEmpty) return true;
                return e.zones.contains(currentZone.id);
              })
              .map((e) => _DropdownOption(id: e.id, label: e.fullName))
              .toList();
          return _buildDropdown(context, options);
        },
        loading: _buildLoading,
        error: (err, _) => _buildError('Blad ladowania: $err'),
      );
    }

    final options = (staticOptions ?? const <String>[])
        .map((opt) => _DropdownOption(id: opt, label: opt))
        .toList();
    return _buildDropdown(context, options);
  }

  Widget _buildLoading() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: HaccpDesignTokens.surface,
        borderRadius: BorderRadius.circular(HaccpDesignTokens.inputRadius),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.centerLeft,
      child: const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: HaccpDesignTokens.primary,
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HaccpDesignTokens.error.withValues(alpha: 0.1),
        border: Border.all(color: HaccpDesignTokens.error),
        borderRadius: BorderRadius.circular(HaccpDesignTokens.inputRadius),
      ),
      child: Text(msg, style: const TextStyle(color: HaccpDesignTokens.error)),
    );
  }

  Widget _buildDropdown(BuildContext context, List<_DropdownOption> options) {
    String? selectedLabel;
    for (final option in options) {
      if (option.id == value) {
        selectedLabel = option.label;
        break;
      }
    }

    return GestureDetector(
      onTap: () => _showSelectionSheet(context, options),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: HaccpDesignTokens.surface,
          borderRadius: BorderRadius.circular(HaccpDesignTokens.inputRadius),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel ?? 'Wybierz z listy...',
                style: TextStyle(
                  fontSize: 16,
                  color: selectedLabel == null ? Colors.white54 : Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context, List<_DropdownOption> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HaccpDesignTokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Wybierz opcje',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (itemCtx, i) {
                  final option = options[i];
                  final isSelected = option.id == value;
                  return ListTile(
                    title: Text(
                      option.label,
                      style: TextStyle(
                        color:
                            isSelected ? HaccpDesignTokens.primary : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: HaccpDesignTokens.primary)
                        : null,
                    onTap: () {
                      onChanged(option.id);
                      Navigator.pop(itemCtx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/haccp_date_picker.dart';
import '../../../../core/models/employee.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/hr_provider.dart';
import '../../../../core/widgets/haccp_num_pad.dart'; // Direct use for consolidated PIN logic

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends ConsumerState<EmployeeProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Listen for global errors from HR controller
    ref.listen(hrControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${next.error}'),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
      }
    });

    final employeesAsync = ref.watch(hrEmployeesProvider);
    final currentUser = ref.read(currentUserProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Profil Pracownika'),
      body: employeesAsync.when(
        data: (employees) {
          final employee = employees.firstWhere(
            (e) => e.id == widget.employeeId,
            orElse: () => Employee(id: 'notFound', fullName: 'Nieznany', role: 'unknown', isActive: false, zones: []),
          );

          if (employee.id == 'notFound') {
            return const Center(child: Text("Nie znaleziono pracownika"));
          }

          final isViewerManager = currentUser?.isManager ?? false;
           // Edit allowed if manager or self (though mostly manager for HR actions)
          final canEdit = isViewerManager;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: HaccpDesignTokens.primary,
                  child: Text(
                    _getInitials(employee.fullName),
                    style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  employee.fullName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  employee.role.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Details Card
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text("Status Aktywny"),
                        value: employee.isActive,
                        onChanged: canEdit ? (val) {
                           ref.read(hrControllerProvider.notifier).toggleActive(employee.id, val);
                        } : null,
                        activeColor: HaccpDesignTokens.success,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text("Ważność badań Sanepid"),
                         subtitle: Text(
                          employee.sanepidExpiry != null 
                              ? DateFormat('yyyy-MM-dd').format(employee.sanepidExpiry!) 
                              : "Brak danych"
                        ),
                        trailing: canEdit ? const Icon(Icons.edit_calendar, color: HaccpDesignTokens.primary) : null,
                        onTap: canEdit ? () async {
                           final picked = await showDatePicker(
                            context: context,
                            initialDate: employee.sanepidExpiry ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: HaccpDesignTokens.primary,
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF1E1E1E),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF1E1E1E),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                             try {
                               await ref.read(hrControllerProvider.notifier).updateSanepid(employee.id, picked);
                               if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Data badań zaktualizowana"),
                                      backgroundColor: HaccpDesignTokens.success,
                                    ),
                                  );
                               }
                             } catch (e) {
                                // Error handled by global listener, but good to have safety here
                             }
                          }
                        } : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                if (canEdit)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_reset),
                      label: const Text("ZMIEŃ PIN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: () => _showChangePinSheet(context, ref, employee.id),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "?";
  }

  void _showChangePinSheet(BuildContext context, WidgetRef ref, String employeeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HaccpDesignTokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ChangePinSheet(employeeId: employeeId),
    );
  }
}

class _ChangePinSheet extends ConsumerStatefulWidget {
  final String employeeId;
  const _ChangePinSheet({required this.employeeId});

  @override
  ConsumerState<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<_ChangePinSheet> {
  String _pin = "";

  void _onDigit(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _submit() async {
    if (_pin.length != 4) return;
    
    await ref.read(hrControllerProvider.notifier).updatePin(widget.employeeId, _pin);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN został zmieniony"), backgroundColor: HaccpDesignTokens.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ustaw Nowy PIN", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? HaccpDesignTokens.primary : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            HaccpNumPad(
              onDigitPressed: _onDigit,
              onClear: () => setState(() => _pin = ""),
              onBackspace: _onBackspace,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _pin.length == 4 ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HaccpDesignTokens.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text("ZAPISZ PIN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

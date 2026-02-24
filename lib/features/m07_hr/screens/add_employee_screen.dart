import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/haccp_num_pad.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../providers/hr_provider.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _role = 'cook';
  String _pin = '';
  DateTime? _sanepidDate;
  final List<String> _selectedZones = <String>[];

  bool _isPinUnique = false;
  bool _isCheckingPin = false;
  String? _pinError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onPinChanged(String newPin) {
    setState(() {
      _pin = newPin;
      _pinError = null;
      _isPinUnique = false;
    });

    if (_pin.length == 4) {
      _checkPinUniqueness();
    }
  }

  Future<void> _checkPinUniqueness() async {
    setState(() => _isCheckingPin = true);

    try {
      final isUnique = await ref.read(hrControllerProvider.notifier).checkPinUnique(_pin);
      if (!mounted) return;
      setState(() {
        _isCheckingPin = false;
        _isPinUnique = isUnique;
        if (!isUnique) {
          _pinError = 'PIN jest juz zajety.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingPin = false;
        _isPinUnique = false;
        _pinError = 'Nie udalo sie sprawdzic PIN. Sprobuj ponownie.';
      });
    }
  }

  void _showPinPad() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.backgroundColor,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 500,
              child: Column(
                children: <Widget>[
                  Text(
                    'Wprowadz 4-cyfrowy PIN',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _pin.padRight(4, '*').replaceAll(RegExp(r'\d'), '*'),
                    style: const TextStyle(
                      fontSize: 40,
                      letterSpacing: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: HaccpNumPad(
                      onDigitPressed: (digit) {
                        if (_pin.length < 4) {
                          _onPinChanged(_pin + digit);
                          setSheetState(() {});
                        }
                      },
                      onClear: () {
                        _onPinChanged('');
                        setSheetState(() {});
                      },
                      onBackspace: () {
                        if (_pin.isNotEmpty) {
                          _onPinChanged(_pin.substring(0, _pin.length - 1));
                          setSheetState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => sheetContext.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('GOTOWE'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveEmployee() async {
    if (ref.read(hrControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN musi miec 4 cyfry.')),
      );
      return;
    }

    if (!_isPinUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN musi byc unikalny.')),
      );
      return;
    }

    if (_sanepidDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz date badan Sanepid.')),
      );
      return;
    }

    if (_selectedZones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Przypisz przynajmniej jedna strefe.')),
      );
      return;
    }

    try {
      await ref.read(hrControllerProvider.notifier).createEmployee(
            fullName: _nameController.text.trim(),
            pin: _pin,
            role: _role,
            sanepidExpiry: _sanepidDate,
            zoneIds: _selectedZones,
          );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hrControllerState = ref.watch(hrControllerProvider);
    final isSubmitting = hrControllerState.isLoading;
    final zonesAsync = ref.watch(hrZonesProvider);
    final currentZone = ref.watch(currentZoneProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            HaccpTopBar(
              title: 'Dodaj Pracownika',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Imie i Nazwisko', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Wpisz imie i nazwisko',
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Podaj imie i nazwisko' : null,
                      ),
                      const SizedBox(height: 24),
                      Text('Rola', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          _buildRoleChip('Pracownik', 'cook'),
                          const SizedBox(width: 16),
                          _buildRoleChip('Manager', 'manager'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Kod PIN (4 cyfry)', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showPinPad,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _pinError != null
                                  ? DesignTokens.errorColor
                                  : (_isPinUnique ? DesignTokens.successColor : Colors.white24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                _pin.isEmpty ? 'Dotknij aby wpisac PIN' : _pin.replaceAll(RegExp(r'.'), '*'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  letterSpacing: _pin.isEmpty ? 0 : 8,
                                  color: _pin.isEmpty ? Colors.white54 : Colors.white,
                                ),
                              ),
                              if (_isCheckingPin)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else if (_pin.length == 4)
                                Icon(
                                  _isPinUnique ? Icons.check_circle : Icons.error,
                                  color: _isPinUnique ? DesignTokens.successColor : DesignTokens.errorColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_pinError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            _pinError!,
                            style: const TextStyle(color: DesignTokens.errorColor, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('Przypisz Strefy', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      zonesAsync.when(
                        data: (zones) {
                          final availableZones = currentZone == null
                              ? zones
                              : zones.where((z) => z.venueId == currentZone.venueId).toList();

                          return Wrap(
                            spacing: 8,
                            children: availableZones.map((zone) {
                              final isSelected = _selectedZones.contains(zone.id);
                              return FilterChip(
                                label: Text(zone.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedZones.add(zone.id);
                                    } else {
                                      _selectedZones.remove(zone.id);
                                    }
                                  });
                                },
                                backgroundColor: Colors.white10,
                                selectedColor: DesignTokens.accentColor.withOpacity(0.3),
                                labelStyle: TextStyle(
                                  color: isSelected ? DesignTokens.accentColor : Colors.white70,
                                ),
                                checkmarkColor: DesignTokens.accentColor,
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text(
                          'Blad pobierania stref: $e',
                          style: const TextStyle(color: DesignTokens.errorColor),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Waznosc badan', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (date != null) {
                            setState(() => _sanepidDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                _sanepidDate == null
                                    ? 'Wybierz date'
                                    : DateFormat('dd.MM.yyyy').format(_sanepidDate!),
                                style: theme.textTheme.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_pin.length == 4 && _isPinUnique && !isSubmitting)
                              ? _saveEmployee
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white10,
                            disabledForegroundColor: Colors.white38,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('ZAPISZ PRACOWNIKA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String value) {
    final isSelected = _role == value;
    final color = isSelected ? DesignTokens.accentColor : Colors.white10;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? DesignTokens.accentColor : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? DesignTokens.accentColor : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

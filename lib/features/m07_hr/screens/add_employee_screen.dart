import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/haccp_num_pad.dart';
import '../../../../core/constants/design_tokens.dart';
import '../providers/hr_provider.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _role = 'cook'; // Default role
  String _pin = '';
  DateTime? _sanepidDate;
  
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
    
    // Simulate delay or waiting for real DB check
    final isUnique = await ref.read(hrControllerProvider.notifier).checkPinUnique(_pin);
    
    if (mounted) {
      setState(() {
        _isCheckingPin = false;
        _isPinUnique = isUnique;
        if (!isUnique) {
          _pinError = 'PIN jest już zajęty!';
        }
      });
    }
  }

  void _showPinPad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundColor,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 500,
          child: Column(
            children: [
              Text(
                'Wprowadź 4-cyfrowy PIN',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              // PIN Display in Modal
              Text(
                _pin.padRight(4, '•').replaceAll(RegExp(r'\d'), '*'), // Masked
                style: const TextStyle(
                  fontSize: 40, 
                  letterSpacing: 16, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: HaccpNumPad(
                  onDigitPressed: (digit) {
                    if (_pin.length < 4) {
                      _onPinChanged(_pin + digit);
                      (context as Element).markNeedsBuild(); // Refresh modal UI
                    }
                  },
                  onClear: () {
                     _onPinChanged('');
                     (context as Element).markNeedsBuild();
                  },
                  onBackspace: () {
                    if (_pin.isNotEmpty) {
                      _onPinChanged(_pin.substring(0, _pin.length - 1));
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
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
    ).then((_) {
      // Refresh parent UI after modal closes
      setState(() {});
    });
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN musi mieć 4 cyfry!')),
      );
      return;
    }
    if (!_isPinUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN musi być unikalny!')),
      );
      return;
    }
    if (_sanepidDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz datę badań Sanepid!')),
      );
      return;
    }

    try {
      // Call Provider to create
      await ref.read(hrControllerProvider.notifier).createEmployee(
        fullName: _nameController.text,
        pin: _pin,
        role: _role,
        sanepidExpiry: _sanepidDate,
      );

      if (mounted) {
        context.pop(true); // Return true to signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Błąd: $e'),
             backgroundColor: DesignTokens.errorColor,
           ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                    children: [
                      // Name
                      Text('Imię i Nazwisko', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Wpisz imię i nazwisko',
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Podaj imię' : null,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Role
                      Text('Rola', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRoleChip('Pracownik', 'cook'),
                          const SizedBox(width: 16),
                          _buildRoleChip('Manager', 'manager'),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // PIN
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
                            children: [
                              Text(
                                _pin.isEmpty ? 'Dotknij aby wpisać PIN' : _pin.replaceAll(RegExp(r'.'), '•'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  letterSpacing: _pin.isEmpty ? 0 : 8,
                                  color: _pin.isEmpty ? Colors.white54 : Colors.white,
                                ),
                              ),
                              if (_isCheckingPin)
                                const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
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
                            style: TextStyle(color: DesignTokens.errorColor, fontSize: 12),
                          ),
                        ),
                        
                      const SizedBox(height: 24),
                      
                      // Sanepid
                      Text('Ważność Badań', style: theme.textTheme.labelLarge),
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
                            children: [
                              Text(
                                _sanepidDate == null 
                                    ? 'Wybierz datę' 
                                    : DateFormat('dd.MM.yyyy').format(_sanepidDate!),
                                style: theme.textTheme.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_pin.length == 4 && _isPinUnique) ? _saveEmployee : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white10,
                            disabledForegroundColor: Colors.white38,
                          ),
                          child: const Text('ZAPISZ PRACOWNIKA'),
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
              color: isSelected ? DesignTokens.accentColor : Colors.transparent
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

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/features/shared/widgets/dynamic_form/haccp_numpad_input.dart';

import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/haccp_long_press_button.dart';
import '../../shared/widgets/dynamic_form/haccp_toggle.dart';
import '../../../../core/constants/design_tokens.dart';
import '../providers/m08_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/repositories/auth_repository.dart';

class GlobalSettingsScreen extends ConsumerStatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  ConsumerState<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends ConsumerState<GlobalSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _nipValue = '';
  
  bool _isLoading = false;
  String? _logoUrl;
  Uint8List? _newLogoBytes;
  String? _venueId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVenue();
    });
  }

  Future<void> _initVenue() async {
    final employee = ref.read(currentUserProvider);
    if (employee == null) return;

    final zones = await AuthRepository().getZonesForEmployee(employee.id);
    if (zones.isNotEmpty) {
      if (mounted) {
        setState(() {
          _venueId = zones.first.venueId;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybieranie logo niedostępne w przeglądarce')),
      );
      return;
    }
    // On mobile, image_picker would be used here
    // For web compatibility, this is disabled
  }

  Future<void> _saveSettings() async {
    if (_venueId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      String? uploadedUrl;
      if (_newLogoBytes != null) {
        uploadedUrl = await ref.read(venueSettingsControllerProvider(_venueId!).notifier)
            .uploadLogoBytes(_newLogoBytes!, 'jpg');
      } else {
        uploadedUrl = _logoUrl; 
      }

      await ref.read(venueSettingsControllerProvider(_venueId!).notifier).updateSettings(
        name: _nameController.text,
        nip: _nipValue,
        address: _addressController.text,
        logoUrl: uploadedUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ustawienia zapisane!'),
            backgroundColor: HaccpDesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_venueId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final settingsAsync = ref.watch(venueSettingsControllerProvider(_venueId!));
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HaccpTopBar(
              title: 'Ustawienia Lokalu',
              onBackPressed: () => context.go('/hub'),
            ),
            
            Expanded(
              child: settingsAsync.when(
                data: (settings) {
                  if (settings != null && _nameController.text.isEmpty && _addressController.text.isEmpty && _nipValue.isEmpty) {
                    _nameController.text = settings['name'] ?? '';
                    _addressController.text = settings['address'] ?? '';
                    _nipValue = settings['nip'] ?? '';
                    _logoUrl = settings['logo_url'];
                  }
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Branding Section
                        _buildSectionHeader('Branding Lokalu', theme),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                                image: _newLogoBytes != null 
                                  ? DecorationImage(
                                      image: MemoryImage(_newLogoBytes!), 
                                      fit: BoxFit.cover
                                    )
                                  : (_logoUrl != null 
                                      ? DecorationImage(
                                          image: NetworkImage(_logoUrl!), 
                                          fit: BoxFit.cover
                                        )
                                      : null),
                              ),
                              child: (_newLogoBytes == null && _logoUrl == null)
                                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white54)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                         Center(
                          child: Text(
                            'Dotknij aby zmienić logo', 
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54)
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Details Section
                        _buildSectionHeader('Dane Firmowe', theme),
                        const SizedBox(height: 16),
                        _buildTextField('Nazwa Lokalu', _nameController),
                        const SizedBox(height: 16),
                        HaccpNumPadInput(
                          label: 'NIP',
                          textValue: _nipValue,
                          onTextChanged: (val) => setState(() => _nipValue = val),
                          maxLength: 10,
                        ),
                         const SizedBox(height: 16),
                        _buildTextField('Adres', _addressController),
                        
                        const SizedBox(height: 32),
                        
                        // System Settings (Mock)
                        _buildSectionHeader('System', theme),
                        const SizedBox(height: 16),
                        _buildToggleRow('Tryb Ciemny', true, (v) {}),
                        const SizedBox(height: 16),
                        _buildToggleRow('Dźwięki Powiadomień', true, (v) {}),
                        
                        const SizedBox(height: 48),
                        
                        // Save Button
                        Center(
                          child: _isLoading 
                            ? const CircularProgressIndicator()
                            : HaccpLongPressButton(
                                label: 'ZAPISZ USTAWIENIA',
                                onCompleted: _saveSettings,
                                color: HaccpDesignTokens.primary,
                              ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Błąd: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(
          color: HaccpDesignTokens.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        )),
        const Divider(color: Colors.white24),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        HaccpToggle(
          value: value,
          onChanged: (val) => onChanged(val ?? false),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/haccp_long_press_button.dart';
import '../../../../core/widgets/haccp_toggle.dart';
import '../../../../core/constants/design_tokens.dart';
import '../providers/m08_providers.dart';
import '../../../../core/providers/auth_provider.dart';

class GlobalSettingsScreen extends ConsumerStatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  ConsumerState<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends ConsumerState<GlobalSettingsScreen> {
  final _nameController = TextEditingController();
  final _nipController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  String? _logoUrl;
  File? _newLogoFile;

  @override
  void initState() {
    super.initState();
    // Fetch settings for current venue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final employee = ref.read(currentEmployeeProvider);
    // Assuming 1st zone's venue_id is the venue, or auth provider has venue_id
    // Simplified: fetch first venue found or hardcoded for single-tenant
    // But since we don't have venue_id readily available in employee model yet (it's in employee_zones), 
    // let's assume we pass it or get it.
    
    // WORKAROUND: For now, we'll try to get it from the first zone or a known ID.
    // Ideally, AuthProvider should expose `currentVenueId`.
    // Let's assume 'default' or check if we can get it.
    
    // For this implementation, we will rely on provider family:
    // But we need the ID to call the provider.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newLogoFile = File(picked.path);
      });
    }
  }

  Future<void> _saveSettings(String venueId) async {
    setState(() => _isLoading = true);
    
    try {
      String? uploadedUrl;
      if (_newLogoFile != null) {
        uploadedUrl = await ref.read(venueSettingsControllerProvider(venueId).notifier).uploadLogo(_newLogoFile!);
      }

      await ref.read(venueSettingsControllerProvider(venueId).notifier).updateSettings(
        name: _nameController.text,
        nip: _nipController.text,
        address: _addressController.text,
        logoUrl: uploadedUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ustawienia zapisane!'),
            backgroundColor: DesignTokens.successColor,
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
    // In a real app, venueId comes from Auth
    // Hardcoding 'default' or getting from user context if available
    // Let's assume the user has access to at least one venue.
    // For now, we will simulate or get from a provider if we updated Auth.
    
    // Since we didn't update Auth to hold venueId, let's use a placeholder or 
    // fetch it inside the widget if we had a way.
    // Let's assume venue_id is 'ec2e92a4-5678-4901-ab34-567890123456' (mock) or derived.
    
    // Better strategy: Use AsyncValue to load.
    // But for this screen to work, we need an ID.
    final venueId = 'default'; // Replace with real ID logic

    final settingsAsync = ref.watch(venueSettingsControllerProvider(venueId));
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
                  if (settings != null && _nameController.text.isEmpty) {
                    _nameController.text = settings['name'] ?? '';
                    _nipController.text = settings['nip'] ?? '';
                    _addressController.text = settings['address'] ?? '';
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
                                image: _newLogoFile != null 
                                  ? DecorationImage(
                                      image: FileImage(_newLogoFile!), 
                                      fit: BoxFit.cover
                                    )
                                  : (_logoUrl != null 
                                      ? DecorationImage(
                                          image: NetworkImage(_logoUrl!), 
                                          fit: BoxFit.cover
                                        )
                                      : null),
                              ),
                              child: (_newLogoFile == null && _logoUrl == null)
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
                        _buildTextField('NIP', _nipController),
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
                                onAction: () => _saveSettings(venueId),
                                color: DesignTokens.primaryColor,
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
          color: DesignTokens.accentColor,
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
          onChanged: onChanged,
        ),
      ],
    );
  }
}

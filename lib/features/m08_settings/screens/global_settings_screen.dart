import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/features/shared/widgets/dynamic_form/haccp_numpad_input.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/haccp_long_press_button.dart';
import '../../../../core/widgets/haccp_stepper.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/success_overlay.dart';
import '../../shared/widgets/dynamic_form/haccp_toggle.dart';
import '../providers/m08_providers.dart';
import '../repositories/venue_repository.dart';

String? normalizeNipOrNull(String rawNip) {
  final normalized = rawNip.trim();
  return normalized.isEmpty ? null : normalized;
}

String? validateM08SettingsPayload({
  required String name,
  required String address,
  required String? nip,
}) {
  if (name.trim().isEmpty) {
    return 'Nazwa lokalu jest wymagana.';
  }
  if (address.trim().isEmpty) {
    return 'Adres lokalu jest wymagany.';
  }
  if (nip != null && !RegExp(r'^\d{10}$').hasMatch(nip)) {
    return 'NIP musi zawierac dokladnie 10 cyfr.';
  }
  return null;
}

String mapSettingsErrorMessage(Object error) {
  final raw = error.toString().toLowerCase();

  if (raw.contains('m08_storage_deny_or_not_found') ||
      raw.contains('m08_storage_unknown')) {
    return 'Blad zapisu logo. Sprawdz uprawnienia Storage i sprobuj ponownie.';
  }
  if (raw.contains('m08_db_constraint')) {
    return 'Nieprawidlowe dane formularza. Sprawdz pola i sprobuj ponownie.';
  }
  if (raw.contains('m08_db_rls_deny')) {
    return 'Brak uprawnien do zapisu ustawien lokalu.';
  }
  if (raw.contains('venues_temp_interval_check')) {
    return 'Nieprawidlowy interwal. Dozwolone wartosci: 5, 15, 60.';
  }
  if (raw.contains('venues_temp_threshold_check')) {
    return 'Prog alarmowy musi byc w zakresie 0-15.';
  }
  if (raw.contains('venues_nip_digits_check')) {
    return 'NIP musi zawierac dokladnie 10 cyfr.';
  }
  if (raw.contains('row-level security') || raw.contains('permission denied')) {
    return 'Brak uprawnien do zapisu ustawien lokalu.';
  }

  return 'Nie udalo sie zapisac ustawien. Sprobuj ponownie.';
}

class GlobalSettingsScreen extends ConsumerStatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  ConsumerState<GlobalSettingsScreen> createState() =>
      _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends ConsumerState<GlobalSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  String _nipValue = '';
  bool _isSaving = false;
  String? _logoUrl;
  Uint8List? _newLogoBytes;

  int _measurementInterval = 15;
  double _alertThreshold = 8.0;

  // Local-only settings (not persisted yet).
  bool _darkModeLocal = true;
  bool _soundsEnabledLocal = true;

  bool _loggedMissingZone = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    if (!kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload logo na mobile nie jest jeszcze wdrozony.'),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _newLogoBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _saveSettings(String venueId) async {
    final normalizedName = _nameController.text.trim();
    final normalizedAddress = _addressController.text.trim();
    final normalizedNipOrNull = normalizeNipOrNull(_nipValue);

    final validationError = validateM08SettingsPayload(
      name: normalizedName,
      address: normalizedAddress,
      nip: normalizedNipOrNull,
    );
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('[M08] saveSettings start venueId=$venueId');

    try {
      String? uploadedUrl;
      if (_newLogoBytes != null) {
        final logoUploaded = await _uploadLogoWithRetry(venueId);
        if (!logoUploaded) {
          return;
        }
        uploadedUrl = _logoUrl;
      } else {
        uploadedUrl = _logoUrl;
      }

      await ref
          .read(venueSettingsControllerProvider(venueId).notifier)
          .updateSettings(
            name: normalizedName,
            nip: normalizedNipOrNull,
            address: normalizedAddress,
            logoUrl: uploadedUrl,
            tempInterval: _measurementInterval,
            tempThreshold: _alertThreshold,
          );

      if (mounted) {
        setState(() {
          _newLogoBytes = null;
        });
      }
      if (!mounted) return;
      await HaccpSuccessOverlay.show(context, message: 'USTAWIENIA ZAPISANE');
    } catch (e) {
      debugPrint('[M08] saveSettings error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapSettingsErrorMessage(e))));
    } finally {
      debugPrint('[M08] saveSettings end');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _uploadLogoWithRetry(String venueId) async {
    while (mounted && _newLogoBytes != null) {
      try {
        final uploadedUrl = await ref
            .read(venueSettingsControllerProvider(venueId).notifier)
            .uploadLogoBytes(_newLogoBytes!, 'jpg');
        if (!mounted) return false;
        setState(() {
          _logoUrl = uploadedUrl;
          _newLogoBytes = null;
        });
        return true;
      } on M08SettingsException catch (e) {
        if (!mounted) return false;
        final retry = await _showLogoUploadFailedDialog(
          mapSettingsErrorMessage(e),
        );
        if (!retry) {
          return false;
        }
      } catch (e) {
        if (!mounted) return false;
        final retry = await _showLogoUploadFailedDialog(
          mapSettingsErrorMessage(e),
        );
        if (!retry) {
          return false;
        }
      }
    }
    return _newLogoBytes == null;
  }

  Future<bool> _showLogoUploadFailedDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Blad zapisu logo'),
        content: Text('$message\n\nSprobowac ponownie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj zapis'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sprobuj ponownie'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentZone = ref.watch(currentZoneProvider);
    final venueId = currentZone?.venueId;

    if (venueId == null) {
      if (!_loggedMissingZone) {
        debugPrint('[M08] missing currentZone -> error state');
        _loggedMissingZone = true;
      }
      return _MissingZoneState();
    }

    _loggedMissingZone = false;

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
                  if (settings != null &&
                      _nameController.text.isEmpty &&
                      _addressController.text.isEmpty &&
                      _nipValue.isEmpty) {
                    _nameController.text = settings['name'] ?? '';
                    _addressController.text = settings['address'] ?? '';
                    _nipValue = settings['nip'] ?? '';
                    _logoUrl = settings['logo_url'];
                    _measurementInterval = settings['temp_interval'] ?? 15;
                    _alertThreshold =
                        (settings['temp_threshold'] as num?)?.toDouble() ?? 8.0;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                        fit: BoxFit.cover,
                                      )
                                    : (_logoUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(_logoUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                              ),
                              child: (_newLogoBytes == null && _logoUrl == null)
                                  ? const Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.white54,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Dotknij, aby zmienic logo (web).',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Dane Firmowe', theme),
                        const SizedBox(height: 16),
                        _buildTextField('Nazwa Lokalu', _nameController),
                        const SizedBox(height: 16),
                        HaccpNumPadInput(
                          label: 'NIP',
                          textValue: _nipValue,
                          onTextChanged: (val) =>
                              setState(() => _nipValue = val),
                          maxLength: 10,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Adres', _addressController),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Menu i Produkty', theme),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text(
                            'Zarzadzaj produktami',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Edytuj liste produktow dla procesow GMP.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          leading: const Icon(
                            Icons.restaurant_menu,
                            color: HaccpDesignTokens.primary,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 16,
                          ),
                          onTap: () => context.push('/settings/products'),
                          tileColor: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Sensory Temperatury', theme),
                        const SizedBox(height: 16),
                        const Text(
                          'Interwal Pomiaru',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 5, label: Text('5 min')),
                            ButtonSegment(value: 15, label: Text('15 min')),
                            ButtonSegment(value: 60, label: Text('60 min')),
                          ],
                          selected: {_measurementInterval},
                          onSelectionChanged: (Set<int> selection) {
                            setState(() {
                              _measurementInterval = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Prog Alarmowy (°C)',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        HaccpStepper(
                          value: _alertThreshold,
                          onChanged: (val) =>
                              setState(() => _alertThreshold = val),
                          unit: '°C',
                          min: 0,
                          max: 15,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          'System (lokalne ustawienia)',
                          theme,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ponizsze opcje dzialaja lokalnie i nie sa zapisywane w bazie.',
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 16),
                        _buildToggleRow(
                          'Tryb Ciemny',
                          _darkModeLocal,
                          (v) => setState(() => _darkModeLocal = v),
                        ),
                        const SizedBox(height: 16),
                        _buildToggleRow(
                          'Dzwieki Powiadomien',
                          _soundsEnabledLocal,
                          (v) => setState(() => _soundsEnabledLocal = v),
                        ),
                        const SizedBox(height: 48),
                        Center(
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : HaccpLongPressButton(
                                  label: 'ZAPISZ USTAWIENIA',
                                  onCompleted: () => _saveSettings(venueId),
                                  color: HaccpDesignTokens.primary,
                                ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mapSettingsErrorMessage(err),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                          venueSettingsControllerProvider(venueId),
                        ),
                        child: const Text('Sprobuj ponownie'),
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

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: HaccpDesignTokens.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
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

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        HaccpToggle(value: value, onChanged: (val) => onChanged(val ?? false)),
      ],
    );
  }
}

class _MissingZoneState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HaccpTopBar(
              title: 'Ustawienia Lokalu',
              onBackPressed: () => context.go('/hub'),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                        color: HaccpDesignTokens.warning,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Brak aktywnej strefy.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aby otworzyc ustawienia, wybierz strefe ponownie.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/zone-select'),
                            icon: const Icon(Icons.place),
                            label: const Text('Wybierz strefe'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/hub'),
                            icon: const Icon(Icons.home),
                            label: const Text('Powrot do Hub'),
                          ),
                        ],
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
}

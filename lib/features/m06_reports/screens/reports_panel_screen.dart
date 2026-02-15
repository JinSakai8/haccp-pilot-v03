import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';

class ReportsPanelScreen extends ConsumerStatefulWidget {
  const ReportsPanelScreen({super.key});

  @override
  ConsumerState<ReportsPanelScreen> createState() => _ReportsPanelScreenState();
}

class _ReportsPanelScreenState extends ConsumerState<ReportsPanelScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedReportType = 'waste';
  String? _selectedSensorId;
  String? _selectedSensorName;

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Raportowanie'),
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Selector Row
            Row(
              children: [
                Expanded(
                  child: _buildSelector(
                    label: 'Typ Raportu',
                    value: _getReportLabel(_selectedReportType),
                    onTap: _showTypeSelector,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelector(
                    label: 'Miesiąc',
                    value: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                    onTap: _showMonthSelector,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedReportType == 'temperature') ...[
               _buildSelector(
                 label: 'Urządzenie (Opcjonalnie)',
                 value: _selectedSensorName ?? 'Wszystkie w strefie',
                 onTap: _showSensorSelector,
               ),
               const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),

            // 2. Action Buttons
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                ),
                onPressed: reportsState.isLoading ? null : () {
                  ref.read(reportsProvider.notifier).generateReport(
                    reportType: _selectedReportType,
                    month: _selectedDate,
                    sensorId: _selectedSensorId,
                  );
                },
                icon: reportsState.isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
                label: Text(reportsState.isLoading ? 'GENEROWANIE...' : 'GENERUJ RAPORT (PDF)'),
              ),
            ),

            const SizedBox(height: 32),

            // 3. Preview & Upload Section
            if (reportsState.hasValue && reportsState.value != null) ...[
              _buildReportPreview(reportsState.value!),
            ],
            
            if (reportsState.hasError)
               Container(
                 padding: const EdgeInsets.all(16),
                 color: AppTheme.error.withValues(alpha: 0.1),
                 child: Text(
                   'Błąd: ${reportsState.error}',
                   style: const TextStyle(color: AppTheme.error),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview(ReportData reportData) {
    final isHtml = reportData.fileName.toLowerCase().endsWith('.html');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raport wygenerowany pomyślnie!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurface),
                    ),
                    Text(
                      reportData.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isHtml) ...[
                 Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Save/Open HTML (Cross-platform way using PdfService/Drive or just local open)
                      // For now, on web we might want to just download/open blob.
                      // Since we are inside the app, maybe just Drive upload is safer for Kiosk?
                      // But requirement says "Open in browser to print".
                       ref.read(pdfServiceProvider).openFile(
                        reportData.bytes, 
                        reportData.fileName
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('OTWÓRZ (DRUKUJ)'),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Podgląd PDF niedostępny w przeglądarce')),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('PODGLĄD'),
                  ),
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: AppTheme.onSecondary,
                  ),
                  onPressed: () async {
                    await ref.read(reportsProvider.notifier).uploadCurrentReport();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Raport wysłany na Google Drive!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('WYŚLIJ NA DRIVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(value, style: const TextStyle(color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold))),
                const Icon(Icons.arrow_drop_down, color: AppTheme.onSurface),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getReportLabel(String type) {
    switch (type) {
      case 'waste': return 'Ewidencja Odpadów';
      case 'gmp': return 'Logs GMP';
      case 'ghp': return 'Checklisty GHP';
      case 'temperature': return 'Rejestr Temperatur';
      default: return type;
    }
  }

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption('waste'),
          _buildOption('gmp'),
          _buildOption('ghp'),
          _buildOption('temperature'),
        ],
      ),
    );
  }

  ListTile _buildOption(String type) {
    return ListTile(
      title: Text(_getReportLabel(type), style: const TextStyle(color: AppTheme.onSurface)),
      onTap: () {
        setState(() => _selectedReportType = type);
        Navigator.pop(context);
      },
    );
  }

  void _showMonthSelector() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showSensorSelector() {
    final zone = ref.read(currentZoneProvider);
    if (zone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz strefę w menu głównym')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        final sensorsAsync = ref.watch(activeSensorsProvider(zone.id));
        return sensorsAsync.when(
          data: (sensors) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Wszystkie w strefie', style: TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  setState(() {
                    _selectedSensorId = null;
                    _selectedSensorName = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ...sensors.map((s) => ListTile(
                title: Text(s.name, style: const TextStyle(color: AppTheme.onSurface)),
                onTap: () {
                  setState(() {
                    _selectedSensorId = s.id;
                    _selectedSensorName = s.name;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          )),
          error: (e, __) => Center(child: Text('Błąd: $e')),
        );
      },
    );
  }
}

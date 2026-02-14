import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';

class ReportsPanelScreen extends ConsumerStatefulWidget {
  const ReportsPanelScreen({super.key});

  @override
  ConsumerState<ReportsPanelScreen> createState() => _ReportsPanelScreenState();
}

class _ReportsPanelScreenState extends ConsumerState<ReportsPanelScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedReportType = 'waste';

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsNotifierProvider);

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
            const SizedBox(height: 32),

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
                 color: AppTheme.error.withOpacity(0.1),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement in-memory PDF preview for web
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Podgląd PDF niedostępny w przeglądarce')),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('PODGLĄD'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: AppTheme.onSecondary,
                  ),
                  onPressed: () async {
                    await ref.read(reportsNotifierProvider.notifier).uploadCurrentReport();
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
}

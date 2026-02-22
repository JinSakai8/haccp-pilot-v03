import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: HaccpTopBar(
        title: 'Raportowanie',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Archiwum Raportow',
            onPressed: () => context.push('/reports/history'),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                    label: 'Miesiac',
                    value:
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                    onTap: _showMonthSelector,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedReportType == 'temperature') ...[
              _buildSelector(
                label: 'Urzadzenie',
                value: _selectedSensorName ?? 'Wybierz urzadzenie',
                onTap: _showSensorSelector,
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                ),
                onPressed: reportsState.isLoading
                    ? null
                    : () {
                        if (_selectedReportType == 'temperature' &&
                            (_selectedSensorId == null ||
                                _selectedSensorId!.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Wybierz urzadzenie przed generowaniem raportu CCP-1.',
                              ),
                            ),
                          );
                          return;
                        }

                        ref.read(reportsProvider.notifier).generateReport(
                              reportType: _selectedReportType,
                              month: _selectedDate,
                              sensorId: _selectedSensorId,
                            );
                      },
                icon: reportsState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  reportsState.isLoading
                      ? 'GENEROWANIE...'
                      : 'GENERUJ RAPORT (PDF)',
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (reportsState.hasValue && reportsState.value != null) ...[
              _buildReportPreview(reportsState.value!),
            ],
            if (reportsState.hasError)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.error.withValues(alpha: 0.1),
                child: Text(
                  'Blad: ${reportsState.error}',
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
                      'Raport wygenerowany pomyslnie!',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.onSurface),
                    ),
                    Text(
                      reportData.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
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
                    ref
                        .read(pdfServiceProvider)
                        .openFile(reportData.bytes, reportData.fileName);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('POBIERZ PDF'),
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
                    await ref.read(reportsProvider.notifier).uploadCurrentReport();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Raport wyslany na Google Drive!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('WYSLIJ NA DRIVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
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
            Text(
              label,
              style:
                  const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
      case 'waste':
        return 'Ewidencja Odpadow';
      case 'gmp':
        return 'Logs GMP';
      case 'ghp':
        return 'Checklisty GHP';
      case 'temperature':
        return 'Rejestr Temperatur';
      default:
        return type;
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
      title: Text(
        _getReportLabel(type),
        style: const TextStyle(color: AppTheme.onSurface),
      ),
      onTap: () {
        setState(() {
          _selectedReportType = type;
          if (type != 'temperature') {
            _selectedSensorId = null;
            _selectedSensorName = null;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  void _showMonthSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _MonthYearPicker(
        initialDate: _selectedDate,
        onDateSelected: (date) {
          setState(() => _selectedDate = date);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSensorSelector() {
    final zone = ref.read(currentZoneProvider);
    if (zone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz strefe w menu glownym (na gorze)'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => Consumer(
        builder: (context, modalRef, _) {
          final sensorsAsync = modalRef.watch(activeSensorsProvider(zone.id));
          return sensorsAsync.when(
            data: (sensors) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Wybierz urzadzenie (${sensors.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text(
                        'Wymagany wybor 1 urzadzenia',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: Icon(Icons.info_outline, color: AppTheme.primary),
                    ),
                    if (sensors.isEmpty)
                      ListTile(
                        title: Text(
                          'Brak czujnikow w strefie "${zone.name}"',
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        subtitle: const Text(
                          'Upewnij sie, ze sensory sa przypisane do tej strefy i aktywne.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ...sensors.map(
                      (s) => ListTile(
                        title: Text(
                          s.name,
                          style: const TextStyle(color: AppTheme.onSurface),
                        ),
                        leading: const Icon(
                          Icons.thermostat,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        trailing: _selectedSensorId == s.id
                            ? const Icon(Icons.check, color: AppTheme.success)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedSensorId = s.id;
                            _selectedSensorName = s.name;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Blad: $e',
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthYearPicker({required this.initialDate, required this.onDateSelected});

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Wybierz miesiac',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left, color: AppTheme.onSurface),
              ),
              Text(
                '$_year',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _year >= DateTime.now().year
                    ? null
                    : () => setState(() => _year++),
                icon: Icon(
                  Icons.chevron_right,
                  color: _year >= DateTime.now().year
                      ? Colors.grey
                      : AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.0,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isCurrent =
                  _year == DateTime.now().year && month == DateTime.now().month;
              final isSelected =
                  _year == widget.initialDate.year && month == widget.initialDate.month;
              final isFuture =
                  _year == DateTime.now().year && month > DateTime.now().month;

              const months = [
                'Styczen',
                'Luty',
                'Marzec',
                'Kwiecien',
                'Maj',
                'Czerwiec',
                'Lipiec',
                'Sierpien',
                'Wrzesien',
                'Pazdziernik',
                'Listopad',
                'Grudzien',
              ];

              return InkWell(
                onTap: isFuture
                    ? null
                    : () {
                        widget.onDateSelected(DateTime(_year, month));
                      },
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : (isFuture
                            ? Colors.transparent
                            : AppTheme.surface.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent
                        ? Border.all(color: AppTheme.primary)
                        : Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    months[index],
                    style: TextStyle(
                      color: isFuture
                          ? Colors.grey
                          : (isSelected
                              ? AppTheme.onPrimary
                              : AppTheme.onSurface),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

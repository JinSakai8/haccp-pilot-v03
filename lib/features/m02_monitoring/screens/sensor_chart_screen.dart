import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/constants/design_tokens.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';
import 'package:intl/intl.dart';

enum _SensorViewMode { chart24h, chart7d, chart30d, table7d }

class SensorChartScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const SensorChartScreen({super.key, required this.deviceId});

  @override
  ConsumerState<SensorChartScreen> createState() => _SensorChartScreenState();
}

class _SensorChartScreenState extends ConsumerState<SensorChartScreen> {
  _SensorViewMode _viewMode = _SensorViewMode.chart24h;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = _isTableMode
        ? null
        : ref.watch(sensorHistoryProvider(widget.deviceId, _selectedRange));
    final tableAsync = _isTableMode
        ? ref.watch(sensorSevenDayTableProvider(widget.deviceId))
        : null;

    return Scaffold(
      appBar: HaccpTopBar(title: 'Sensor: ${widget.deviceId}'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnotationSheet(context),
        label: const Text('Dodaj adnotacje'),
        icon: const Icon(Icons.note_add),
        backgroundColor: HaccpDesignTokens.primary,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildModeChip('24h', _SensorViewMode.chart24h),
                _buildModeChip('7 dni', _SensorViewMode.chart7d),
                _buildModeChip('30 dni', _SensorViewMode.chart30d),
                _buildModeChip('Tabela 7 dni', _SensorViewMode.table7d),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 16,
                left: 12,
                bottom: 16,
                top: 4,
              ),
              child: _isTableMode
                  ? _buildTableSection(context, tableAsync!)
                  : _buildChartSection(historyAsync!),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isTableMode => _viewMode == _SensorViewMode.table7d;

  Duration get _selectedRange {
    switch (_viewMode) {
      case _SensorViewMode.chart24h:
        return const Duration(hours: 24);
      case _SensorViewMode.chart7d:
        return const Duration(days: 7);
      case _SensorViewMode.chart30d:
        return const Duration(days: 30);
      case _SensorViewMode.table7d:
        return const Duration(days: 7);
    }
  }

  Widget _buildChartSection(AsyncValue<List<TemperatureLog>> historyAsync) {
    return historyAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('Brak danych w wybranym okresie'));
        }

        final spots = logs
            .map(
              (log) => FlSpot(
                log.recordedAt.millisecondsSinceEpoch.toDouble(),
                log.temperature,
              ),
            )
            .toList();

        final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 2;
        final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2;

        final oneHourMs = 3600000.0;
        final oneDayMs = 24 * oneHourMs;

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Colors.white12, strokeWidth: 1),
              getDrawingVerticalLine: (_) =>
                  const FlLine(color: Colors.white12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: _selectedRange.inHours > 24 ? oneDayMs : 4 * oneHourMs,
                  getTitlesWidget: (value, _) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    final format = _selectedRange.inHours <= 24
                        ? DateFormat('HH:mm')
                        : DateFormat('MM-dd');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        format.format(date),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, _) => Text(
                    '${value.toInt()}\u00B0C',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white12),
            ),
            minX: spots.first.x,
            maxX: spots.last.x,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: HaccpDesignTokens.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: HaccpDesignTokens.primary.withOpacity(0.1),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 10,
                  color: HaccpDesignTokens.error,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    labelResolver: (_) => 'Limit 10\u00B0C',
                    style: const TextStyle(
                      color: HaccpDesignTokens.error,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Blad: $err')),
    );
  }

  Widget _buildTableSection(
    BuildContext context,
    AsyncValue<List<TemperatureLog>> tableAsync,
  ) {
    final employee = ref.watch(currentUserProvider);
    final canEditRole = employee?.isManager ?? false;
    final editState = ref.watch(temperatureLogEditActionProvider);

    return tableAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('Brak danych tabelarycznych z 7 dni'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Wszystkie pomiary z 7 dni',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Data')),
                      DataColumn(label: Text('Godzina')),
                      DataColumn(label: Text('Temperatura')),
                      DataColumn(label: Text('Alert')),
                      DataColumn(label: Text('Status potwierdzenia')),
                      DataColumn(label: Text('Akcja')),
                    ],
                    rows: logs.map((log) {
                      final canEdit = canEditRole && _isEditableByWindow(log.recordedAt);
                      final editedBadge = log.editedAt != null ? ' (E)' : '';

                      return DataRow(
                        cells: [
                          DataCell(Text(DateFormat('yyyy-MM-dd').format(log.recordedAt))),
                          DataCell(Text(DateFormat('HH:mm').format(log.recordedAt))),
                          DataCell(
                            Text('${log.temperature.toStringAsFixed(1)}\u00B0C$editedBadge'),
                          ),
                          DataCell(
                            Icon(
                              log.isAlert ? Icons.warning_amber_rounded : Icons.check_circle,
                              color: log.isAlert ? Colors.orange : Colors.green,
                            ),
                          ),
                          DataCell(
                            Icon(
                              log.isAcknowledged
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                              color: log.isAcknowledged ? Colors.green : Colors.grey,
                            ),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: canEdit
                                  ? 'Edytuj temperature'
                                  : 'Edycja dostepna tylko dla manager/owner do 7 dni',
                              onPressed: canEdit && !editState.isLoading
                                  ? () => _showEditDialog(context, log)
                                  : null,
                              icon: editState.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.edit),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Blad tabeli: $err')),
    );
  }

  bool _isEditableByWindow(DateTime recordedAt) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return !recordedAt.isBefore(cutoff);
  }

  Widget _buildModeChip(String label, _SensorViewMode mode) {
    final isSelected = _viewMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _viewMode = mode);
        }
      },
      selectedColor: HaccpDesignTokens.primary,
      backgroundColor: Colors.white10,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, TemperatureLog log) async {
    final tempController = TextEditingController(text: log.temperature.toStringAsFixed(1));
    final reasonController = TextEditingController(text: log.editReason ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edytuj temperature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nowa temperatura',
                  hintText: 'np. 4.5',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Powod (opcjonalnie)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ANULUJ'),
            ),
            FilledButton(
              onPressed: () async {
                final raw = tempController.text.trim().replaceAll(',', '.');
                final regex = RegExp(r'^-?\d{1,3}(\.\d{1,2})?$');
                if (!regex.hasMatch(raw)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Podaj liczbe max z 2 miejscami po przecinku')),
                  );
                  return;
                }

                final parsed = double.tryParse(raw);
                if (parsed == null || parsed < -50 || parsed > 150) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zakres temperatury: -50..150')),
                  );
                  return;
                }

                await ref
                    .read(temperatureLogEditActionProvider.notifier)
                    .editTemperatureLog(
                      sensorId: widget.deviceId,
                      logId: log.id,
                      value: parsed,
                      reason: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    );

                if (!context.mounted) return;
                Navigator.of(ctx).pop();

                final editState = ref.read(temperatureLogEditActionProvider);
                if (editState.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blad zapisu: ${editState.error}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zapisano zmiane temperatury')),
                  );
                }
              },
              child: const Text('ZAPISZ'),
            ),
          ],
        );
      },
    );

    tempController.dispose();
    reasonController.dispose();
  }

  void _showAnnotationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dodaj adnotacje', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('Dostawa'), onPressed: () {}),
                ActionChip(label: const Text('Mycie'), onPressed: () {}),
                ActionChip(label: const Text('Defrost'), onPressed: () {}),
                ActionChip(label: const Text('Awaria'), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Komentarz (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  const label = 'Adnotacja';
                  await ref
                      .read(annotationActionProvider.notifier)
                      .add(widget.deviceId, label, _commentController.text);

                  if (context.mounted) {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adnotacja zapisana')),
                    );
                  }
                },
                child: const Text('ZAPISZ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

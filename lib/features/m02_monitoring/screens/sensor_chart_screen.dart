import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/constants/design_tokens.dart';
import '../providers/monitoring_provider.dart';

class SensorChartScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const SensorChartScreen({super.key, required this.deviceId});

  @override
  ConsumerState<SensorChartScreen> createState() => _SensorChartScreenState();
}

class _SensorChartScreenState extends ConsumerState<SensorChartScreen> {
  Duration _selectedRange = const Duration(hours: 24);
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(sensorHistoryProvider(widget.deviceId, _selectedRange));

    return Scaffold(
      appBar: HaccpTopBar(title: 'Wykres: ${widget.deviceId}'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAnnotationSheet(context);
        },
        label: const Text('Dodaj Adnotację'),
        icon: const Icon(Icons.note_add),
        backgroundColor: HaccpDesignTokens.primary,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Range Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRangeChip('24h', const Duration(hours: 24)),
                const SizedBox(width: 12),
                _buildRangeChip('7 Dni', const Duration(days: 7)),
                const SizedBox(width: 12),
                _buildRangeChip('30 Dni', const Duration(days: 30)),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, left: 12.0, bottom: 24.0, top: 10),
              child: historyAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text('Brak danych w wybranym okresie'));
                  }

                  // Data Processing
                  final spots = logs.map((log) {
                    return FlSpot(
                      log.recordedAt.millisecondsSinceEpoch.toDouble(),
                      log.temperature,
                    );
                  }).toList();

                  final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 2;
                  final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2;

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _selectedRange.inHours > 24 
                                ? 24 * 60 * 60 * 1000 * 1000 // approx calc, fix later
                                : 4 * 60 * 60 * 1000, 
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              String text;
                              if (_selectedRange.inHours <= 24) {
                                text = DateFormat('HH:mm').format(date);
                              } else {
                                text = DateFormat('MM-dd').format(date);
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}°C', style: const TextStyle(color: Colors.white54, fontSize: 10));
                            },
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
                      // Limits / Thresholds lines
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 10,
                            color: HaccpDesignTokens.error,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) => 'Limit 10°C',
                              style: const TextStyle(color: HaccpDesignTokens.error, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Błąd: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, Duration duration) {
    final isSelected = _selectedRange == duration;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRange = duration);
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

  void _showAnnotationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Dodaj Adnotację', style: Theme.of(context).textTheme.titleLarge),
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
                   final comment = _commentController.text;
                   // Use selected label or default
                   const label = 'Adnotacja'; // TODO: State for selected chip
                   
                   await ref.read(annotationActionProvider.notifier)
                       .add(widget.deviceId, label, comment);
                       
                   if (context.mounted) {
                     Navigator.pop(context);
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

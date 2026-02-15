import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';

class TemperatureDashboardScreen extends ConsumerWidget {
  const TemperatureDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentZone = ref.watch(currentZoneProvider);

    if (currentZone == null) {
      return const Scaffold(
        appBar: HaccpTopBar(title: "Monitoring Temperatur"),
        body: Center(child: Text("Brak wybranej strefy")),
      );
    }

    final activeSensorsAsync = ref.watch(activeSensorsProvider(currentZone.id));
    final latestMeasurementsAsync = ref.watch(latestMeasurementsProvider(currentZone.id));

    return Scaffold(
      appBar: HaccpTopBar(
        title: "Monitoring Temperatur",
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.orange),
            onPressed: () => context.push('/monitoring/alarms'),
          ),
        ],
      ),
      body: activeSensorsAsync.when(
        data: (sensors) {
          if (sensors.isEmpty) {
             return const Center(child: Text("Brak aktywnych sensorów w tej strefie"));
          }

          return latestMeasurementsAsync.when(
            data: (logs) {
              // Map logs to sensors
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sensors.length,
                itemBuilder: (context, index) {
                  final sensor = sensors[index];
                  // Find latest log for this sensor
                  final latestLog = logs
                      .where((l) => l.sensorId == sensor.id)
                      .firstOrNull; // Requires Dart 3

                  return InkWell(
                    onTap: () => context.push('/monitoring/chart/${sensor.id}'),
                    child: _SensorCard(sensor: sensor, latestLog: latestLog),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Błąd strumienia: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd pobierania sensorów: $err')),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final Sensor sensor;
  final TemperatureLog? latestLog;

  const _SensorCard({required this.sensor, this.latestLog});

  @override
  Widget build(BuildContext context) {
    // Basic 10/5/3 Logic (Sample)
    final temp = latestLog?.temperature ?? 0.0;
    final isAlert = latestLog?.isAlert ?? false;
    
    Color tempColor = Theme.of(context).colorScheme.primary; // default
    if (latestLog != null) {
      if (temp <= 10) {
        tempColor = Colors.green; // OK
      } else if (temp > 10 && !isAlert) {
        tempColor = Colors.orange; // Warning
      } else {
        tempColor = Colors.red; // Alert
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sensor.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                if (latestLog != null)
                  Text(
                    "Ostatni pomiar: ${latestLog!.recordedAt.hour}:${latestLog!.recordedAt.minute.toString().padLeft(2, '0')}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  const Text("Brak danych"),
                const SizedBox(height: 4),
                // Additional Mock Info for Dashboard
                Row(
                  children: [
                    const Icon(Icons.refresh, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("Co ${sensor.intervalMinutes} min", style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 16),
                    // Trend Mock
                    const Icon(Icons.trending_flat, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
            if (latestLog != null)
              Text(
                "${temp.toStringAsFixed(1)}°C",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: tempColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
               const Text("--.-°C"),
          ],
        ),
      ),
    );
  }
}

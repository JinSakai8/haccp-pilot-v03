import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/monitoring_provider.dart';
import '../models/temperature_log.dart';

class AlarmsPanelScreen extends ConsumerWidget {
  const AlarmsPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(currentZoneProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: HaccpTopBar(
          title: 'Alarmy Temperatur',
          actions: [
            // Potentially filters
          ],
        ),
        body: Column(
          children: [
            const TabBar(
              indicatorColor: HaccpDesignTokens.primary,
              labelColor: HaccpDesignTokens.primary,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: "AKTYWNE"),
                Tab(text: "HISTORIA"),
              ],
            ),
            Expanded(
              child: zone == null
                  ? const Center(child: Text("Brak wybranej strefy"))
                  : TabBarView(
                      children: [
                        _AlarmsList(zoneId: zone.id, isActive: true),
                        _AlarmsList(zoneId: zone.id, isActive: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmsList extends ConsumerWidget {
  final String zoneId;
  final bool isActive;

  const _AlarmsList({required this.zoneId, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider(zoneId, activeOnly: isActive));
    final sensorsAsync = ref.watch(activeSensorsProvider(zoneId));

    return alarmsAsync.when(
      data: (alarms) {
        return sensorsAsync.when(
          data: (sensors) {
             if (alarms.isEmpty) {
              return HaccpEmptyState(
                headline: isActive ? "Brak aktywnych alarmów" : "Brak historii alarmów",
                subtext: isActive ? "Wszystkie parametry w normie." : "",
                icon: isActive ? Icons.check_circle_outline : Icons.history,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final log = alarms[index];
                final sensor = sensors.where((s) => s.id == log.sensorId).firstOrNull;
                final sensorName = sensor?.name ?? 'Sensor ${log.sensorId.substring(0, 4)}...';
                
                return _AlarmCard(log: log, isActive: isActive, sensorName: sensorName);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Błąd sensorów: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Błąd: $err')),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  final TemperatureLog log;
  final bool isActive;
  final String sensorName;

  const _AlarmCard({required this.log, required this.isActive, required this.sensorName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isActive ? HaccpDesignTokens.error : Colors.white12,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? HaccpDesignTokens.error.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Icon(
            Icons.warning_amber_rounded,
            color: isActive ? HaccpDesignTokens.error : Colors.grey,
          ),
        ),
        title: Text(
          "${log.temperature.toStringAsFixed(1)}°C - $sensorName", 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('yyyy-MM-dd HH:mm').format(log.recordedAt)),
            if (!isActive)
              Text("Potwierdzone", style: TextStyle(color: Colors.green.shade300, fontSize: 12)),
          ],
        ),
        trailing: isActive
            ? ElevatedButton(
                onPressed: () {},
                onLongPress: () {
                   ref.read(alarmActionProvider.notifier).acknowledge(log.id);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Alarm potwierdzony')),
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HaccpDesignTokens.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Przytrzymaj"),
              )
            : const Icon(Icons.check, color: Colors.green),
      ),
    );
  }
}

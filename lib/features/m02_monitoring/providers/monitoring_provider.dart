import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:haccp_pilot/features/m02_monitoring/repositories/measurements_repository.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';

part 'monitoring_provider.g.dart'; 

@riverpod
MeasurementsRepository measurementsRepository(Ref ref) {
  return MeasurementsRepository();
}

@riverpod
Future<List<Sensor>> activeSensors(Ref ref, String zoneId) async {
  final repo = ref.watch(measurementsRepositoryProvider);
  return repo.getSensors(zoneId);
}

@riverpod
Stream<List<TemperatureLog>> latestMeasurements(Ref ref) {
  final repo = ref.watch(measurementsRepositoryProvider);
  return repo.streamLogs();
}

@riverpod
Future<List<TemperatureLog>> sensorHistory(Ref ref, String sensorId, Duration range) async {
  final repo = ref.watch(measurementsRepositoryProvider);
  final to = DateTime.now();
  final from = to.subtract(range);
  
  return repo.getHistory(sensorId, from: from, to: to);
}

@riverpod
Future<List<TemperatureLog>> alarms(Ref ref, String zoneId, {bool activeOnly = true}) async {
  final repo = ref.watch(measurementsRepositoryProvider);
  return repo.getAlerts(zoneId, activeOnly: activeOnly);
}

@riverpod
class AlarmAction extends _$AlarmAction {
  @override
  FutureOr<void> build() {}

  Future<void> acknowledge(String logId) async {
    state = const AsyncLoading();
    final repo = ref.read(measurementsRepositoryProvider);
    // In real app get userId from auth
    const userId = 'curr-user-id'; 
    
    state = await AsyncValue.guard(() => repo.acknowledgeAlert(logId, userId));
    
    // Invalidate badges and alarms list
    ref.invalidate(alarmsProvider);
    // ref.invalidate(dashboardBadgesProvider); // if imported
  }
}

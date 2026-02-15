import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:haccp_pilot/features/m02_monitoring/repositories/measurements_repository.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';

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

// Zaktualizowany stream zależny od sensorów strefy
@riverpod
Stream<List<TemperatureLog>> latestMeasurements(Ref ref, String zoneId) {
  final sensorsAsync = ref.watch(activeSensorsProvider(zoneId));
  
  return sensorsAsync.when(
    data: (sensors) {
      if (sensors.isEmpty) return Stream.value([]);
      final ids = sensors.map((s) => s.id).toList();
      final repo = ref.watch(measurementsRepositoryProvider);
      return repo.streamLogs(ids);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
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
    final user = ref.read(currentUserProvider);
    final userId = user?.id; // Pobierz prawdziwe ID

    if (userId == null) {
      state = AsyncError('Brak zalogowanego użytkownika', StackTrace.current);
      return;
    }
    
    state = await AsyncValue.guard(() => repo.acknowledgeAlert(logId, userId));
    
    // Invalidate badges and alarms list
    // We assume we can get zoneId from context or invalidate all
    ref.invalidate(alarmsProvider);
  }
}

// Nowy akcja do adnotacji
@riverpod
class AnnotationAction extends _$AnnotationAction {
  @override
  FutureOr<void> build() {}

  Future<void> add(String sensorId, String label, String comment) async {
    state = const AsyncLoading();
    final repo = ref.read(measurementsRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final userId = user?.id;

    if (userId == null) {
      state = AsyncError('Brak zalogowanego użytkownika', StackTrace.current);
      return;
    }

    state = await AsyncValue.guard(() => repo.insertAnnotation(sensorId, label, comment, userId));
    
    // Opcjonalnie inwalidacja historii, jeśli adnotacje są tam pobierane
    // ref.invalidate(sensorHistoryProvider); // na razie sensorHistory nie pobiera adnotacji, ale w przyszłości tak
  }
}

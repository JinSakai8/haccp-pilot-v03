import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/alarm_list_item.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/repositories/measurements_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
Future<List<TemperatureLog>> sensorHistory(
  Ref ref,
  String sensorId,
  Duration range,
) async {
  final repo = ref.watch(measurementsRepositoryProvider);
  final to = DateTime.now();
  final from = to.subtract(range);

  return repo.getHistory(sensorId, from: from, to: to);
}

final sensorSevenDayTableProvider =
    FutureProvider.autoDispose.family<List<TemperatureLog>, String>((
      ref,
      sensorId,
    ) async {
      final repo = ref.watch(measurementsRepositoryProvider);
      return repo.getSevenDayTable(sensorId);
    });

@riverpod
Future<List<AlarmListItem>> alarms(
  Ref ref,
  String zoneId, {
  bool activeOnly = true,
}) async {
  final repo = ref.watch(measurementsRepositoryProvider);
  return repo.getAlerts(zoneId, activeOnly: activeOnly);
}

@riverpod
class AlarmAction extends _$AlarmAction {
  @override
  FutureOr<void> build() {}

  Future<void> acknowledge(String logId) async {
    final repo = ref.read(measurementsRepositoryProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) {
      state = AsyncError('Brak zalogowanego uzytkownika', StackTrace.current);
      return;
    }

    await repo.acknowledgeAlert(logId);

    ref.invalidate(alarmsProvider);
  }
}

class TemperatureLogEditAction extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> editTemperatureLog({
    required String sensorId,
    required String logId,
    required double value,
    String? reason,
  }) async {
    if (value < -50 || value > 150) {
      state = AsyncError(
        'Temperatura poza zakresem -50..150',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final repo = ref.read(measurementsRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.editTemperatureLogValue(
        logId: logId,
        newTemperature: value,
        editReason: reason,
      ),
    );

    ref.invalidate(sensorSevenDayTableProvider(sensorId));
    ref.invalidate(sensorHistoryProvider(sensorId, const Duration(hours: 24)));
    ref.invalidate(sensorHistoryProvider(sensorId, const Duration(days: 7)));
    ref.invalidate(sensorHistoryProvider(sensorId, const Duration(days: 30)));
  }
}

final temperatureLogEditActionProvider =
    AsyncNotifierProvider.autoDispose<TemperatureLogEditAction, void>(
      TemperatureLogEditAction.new,
    );

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
      state = AsyncError('Brak zalogowanego uzytkownika', StackTrace.current);
      return;
    }

    state = await AsyncValue.guard(
      () => repo.insertAnnotation(sensorId, label, comment, userId),
    );
  }
}

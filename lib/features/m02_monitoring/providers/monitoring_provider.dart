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

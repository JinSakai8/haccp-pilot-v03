import 'package:collection/collection.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m06_reports/models/daily_temperature_stats.dart';

class TemperatureAggregatorService {
  /// Aggregates a list of raw [TemperatureLog]s into daily statistics per device.
  ///
  /// The algorithm:
  /// 1. Group logs by [sensorId] (assuming we can map this later to a name or use it as key).
  ///    Ideally, we should rely on deviceName if available, but logs might only have sensorId.
  ///    Actually, the logs returned by the repo usually have a joined device name.
  ///    Let's assume the caller provides logs that might need enrichment or just groups by sensorId.
  ///    However, for the report we need the Device Name. 
  ///    In this implementation, we will use [sensorId] for grouping, but we need a way to get the name.
  ///    Since [TemperatureLog] doesn't natively have `deviceName` (it's in the DB join), 
  ///    we might need to extend [TemperatureLog] or pass a map.
  ///    
  ///    For Sprint 1, let's assume `TemperatureLog` or the input list allows us to derive the name.
  ///    Actually, the `TemperatureLog` model currently only has `sensorId`.
  ///    
  ///    Strategy: We will group by `sensorId`. The report generation step (Sprint 2) 
  ///    will map `sensorId` to `deviceName` using a separate lookup or we assume 
  ///    the Aggregator receives enriched data.
  ///    
  ///    WAIT: The `ReportsRepository.getMeasurements` returns `Map<String, dynamic>`.
  ///    Creating `TemperatureLog` from it discards the `devices(name)`.
  ///    We should update `TemperatureLog` or create a subclass `ReportTemperatureLog` that includes the name.
  ///    
  ///    DECISION: For now, I will accept `List<TemperatureLog>` and an optional `Map<String, String>` 
  ///    mapping sensorId -> deviceName. If mapping is missing, use sensorId.
  static List<DailyTemperatureStats> aggregate(
    List<TemperatureLog> logs, {
    Map<String, String>? deviceNames,
  }) {
    final List<DailyTemperatureStats> stats = [];

    // 1. Group by Sensor ID
    final logsBySensor = groupBy(logs, (log) => log.sensorId);

    for (var entry in logsBySensor.entries) {
      final sensorId = entry.key;
      final sensorLogs = entry.value;
      final deviceName = deviceNames?[sensorId] ?? 'Sensor $sensorId';

      // 2. Group by Date (YYYY-MM-DD)
      final logsByDate = groupBy(sensorLogs, (log) {
        return DateTime(log.recordedAt.year, log.recordedAt.month, log.recordedAt.day);
      });

      for (var dateEntry in logsByDate.entries) {
        final date = dateEntry.key;
        final dailyLogs = dateEntry.value;

        if (dailyLogs.isEmpty) continue;

        // 3. Calculate Stats
        double minTemp = double.infinity;
        double maxTemp = double.negativeInfinity;
        double sumTemp = 0.0;
        bool hasBreach = false;

        for (var log in dailyLogs) {
          if (log.temperature < minTemp) minTemp = log.temperature;
          if (log.temperature > maxTemp) maxTemp = log.temperature;
          sumTemp += log.temperature;
          if (log.isAlert) hasBreach = true;
        }

        final avgTemp = sumTemp / dailyLogs.length;

        stats.add(DailyTemperatureStats(
          date: date,
          deviceName: deviceName,
          minTemp: minTemp,
          maxTemp: maxTemp,
          avgTemp: avgTemp,
          measurementCount: dailyLogs.length,
          hasCriticalBreach: hasBreach,
        ));
      }
    }

    // Sort by Date then Device Name
    stats.sort((a, b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.deviceName.compareTo(b.deviceName);
    });

    return stats;
  }
}

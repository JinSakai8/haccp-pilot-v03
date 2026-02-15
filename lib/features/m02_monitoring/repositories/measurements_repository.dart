import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';

class MeasurementsRepository {
  final SupabaseClient _client = SupabaseService.client;

  // Pobierz listę sensorów dla danej strefy
  Future<List<Sensor>> getSensors(String zoneId) async {
    final response = await _client
        .from('sensors')
        .select()
        .eq('zone_id', zoneId)
        .eq('is_active', true);
        
    return (response as List).map((e) => Sensor.fromJson(e)).toList();
  }

  // Stream najnowszych pomiarów (Realtime)
  Stream<List<TemperatureLog>> streamLogs() {
    return _client
        .from('temperature_logs')
        .stream(primaryKey: ['id'])
        .order('recorded_at', ascending: false)
        .limit(20) // Limit to keep memory usage low, we only need latest for dashboard
        .map((data) => data.map((json) => TemperatureLog.fromJson(json)).toList());
  }

  // Pobierz historię pomiarów dla wykresu
  Future<List<TemperatureLog>> getHistory(String sensorId, {required DateTime from, required DateTime to}) async {
    final response = await _client
        .from('temperature_logs')
        .select()
        .eq('sensor_id', sensorId)
        .gte('recorded_at', from.toIso8601String())
        .lte('recorded_at', to.toIso8601String())
        .order('recorded_at', ascending: true); // Ascending for charts

    return (response as List).map((e) => TemperatureLog.fromJson(e)).toList();
  }

  // Pobierz alerty (aktywne lub historyczne)
  Future<List<TemperatureLog>> getAlerts(String zoneId, {bool activeOnly = true}) async {
    var query = _client.from('temperature_logs')
        .select()
        .eq('is_alert', true)
        // We might need to join with sensors to filter by zone, 
        // but for now let's assume we filter in app or if we had zone_id in logs.
        // Since logs don't have zone_id directly typically (normalized), we should filter by sensor IDs from that zone.
        // For Valid MVP: fetch all alerts and filter in memory or assume simplistic model.
        // Better: filtering by sensor_id list.
        .eq('is_acknowledged', !activeOnly) // true = history (ack), false = active (not ack)
        .order('recorded_at', ascending: false);
    
    // FETCH SENSORS FIRST to filter by zone
    final sensors = await getSensors(zoneId);
    final sensorIds = sensors.map((s) => s.id).toList();

    if (sensorIds.isEmpty) return [];

    final response = await query.in_('sensor_id', sensorIds);

    return (response as List).map((e) => TemperatureLog.fromJson(e)).toList();
  }

  Future<void> acknowledgeAlert(String logId, String userId) async {
    await _client.from('temperature_logs').update({
      'is_acknowledged': true,
      'acknowledged_by': userId,
      'acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', logId);
  }
}

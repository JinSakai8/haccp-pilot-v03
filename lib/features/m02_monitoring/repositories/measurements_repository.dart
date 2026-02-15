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

  // Stream najnowszych pomiarów (Realtime) - filtrowany po liście ID sensorów
  Stream<List<TemperatureLog>> streamLogs(List<String> sensorIds) {
    if (sensorIds.isEmpty) return Stream.value([]);

    return _client
        .from('temperature_logs')
        .stream(primaryKey: ['id'])
        .inFilter('sensor_id', sensorIds)
        .order('recorded_at', ascending: false)
        .limit(20)
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
    // 1. FETCH SENSORS FIRST to filter by zone
    final sensors = await getSensors(zoneId);
    final sensorIds = sensors.map((s) => s.id).toList();

    if (sensorIds.isEmpty) return [];

    // 2. Build query with all filters first
    final response = await _client.from('temperature_logs')
        .select()
        .eq('is_alert', true)
        .eq('is_acknowledged', !activeOnly)
        .filter('sensor_id', 'in', sensorIds)
        .order('recorded_at', ascending: false);

    return (response as List).map((e) => TemperatureLog.fromJson(e)).toList();
  }

  Future<void> acknowledgeAlert(String logId, String userId) async {
    await _client.from('temperature_logs').update({
      'is_acknowledged': true,
      'acknowledged_by': userId,
      'acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', logId);
  }

  // Nowa metoda do dodawania adnotacji
  Future<void> insertAnnotation(String sensorId, String label, String comment, String userId) async {
    await _client.from('annotations').insert({
      'sensor_id': sensorId,
      'label': label,
      'comment': comment,
      'created_by': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

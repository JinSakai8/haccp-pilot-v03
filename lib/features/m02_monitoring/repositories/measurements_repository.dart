import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/alarm_list_item.dart';
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

  Future<List<TemperatureLog>> getSevenDayTable(
    String sensorId, {
    int limit = 500,
  }) async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 7));

    final response = await _client
        .from('temperature_logs')
        .select()
        .eq('sensor_id', sensorId)
        .gte('recorded_at', from.toIso8601String())
        .lte('recorded_at', now.toIso8601String())
        .order('recorded_at', ascending: false)
        .limit(limit);

    return (response as List).map((e) => TemperatureLog.fromJson(e)).toList();
  }

  // Pobierz alerty (aktywne lub historyczne)
  Future<List<AlarmListItem>> getAlerts(
    String zoneId, {
    bool activeOnly = true,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'get_temperature_alarms',
      params: {
        'zone_id_input': zoneId,
        'active_only_input': activeOnly,
        'limit_input': limit,
        'offset_input': offset,
      },
    );

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(AlarmListItem.fromJson)
        .toList();
  }

  Future<void> acknowledgeAlert(String logId) async {
    await _client.rpc(
      'acknowledge_temperature_alert',
      params: {
        'log_id_input': logId,
      },
    );
  }

  Future<void> editTemperatureLogValue({
    required String logId,
    required double newTemperature,
    String? editReason,
  }) async {
    await _client.rpc(
      'update_temperature_log_value',
      params: {
        'log_id_input': logId,
        'new_temperature_input': newTemperature,
        'edit_reason_input': editReason,
      },
    );
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

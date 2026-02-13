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
}

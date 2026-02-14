import 'package:haccp_pilot/core/services/supabase_service.dart';

class ReportsRepository {
  Future<List<Map<String, dynamic>>> getWasteRecords(DateTime start, DateTime end) async {
    final response = await SupabaseService.client
        .from('waste_records')
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getGmpLogs(DateTime start, DateTime end) async {
    // Assuming 'gmp_logs' exists
    final response = await SupabaseService.client
        .from('gmp_logs')
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeasurements(DateTime start, DateTime end) async {
    final response = await SupabaseService.client
        .from('measurements')
        .select('*, devices(name)')
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String())
        .order('timestamp');
    
    return List<Map<String, dynamic>>.from(response);
  }
}

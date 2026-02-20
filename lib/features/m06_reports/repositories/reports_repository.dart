import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
import 'package:haccp_pilot/core/services/app_logger.dart';

class ReportsRepository {
  Future<List<Map<String, dynamic>>> getWasteRecords(
    DateTime start,
    DateTime end,
  ) async {
    final response = await SupabaseService.client
        .from('waste_records')
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCoolingLogs(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end =
        start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final response = await SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', 'gmp')
        .eq('form_id', 'food_cooling')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getGmpLogs(DateTime start, DateTime end) async {
    final response = await SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', 'gmp')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeasurements(
    DateTime start,
    DateTime end,
  ) async {
    final response = await SupabaseService.client
        .from('temperature_logs')
        .select('*, sensors(name)')
        .gte('recorded_at', start.toIso8601String())
        .lte('recorded_at', end.toIso8601String())
        .order('recorded_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Uint8List?> getVenueLogo(String venueId) async {
    try {
      final venue = await SupabaseService.client
          .from('venues')
          .select('logo_url')
          .eq('id', venueId)
          .maybeSingle();

      if (venue == null || venue['logo_url'] == null) return null;

      final logoUrl = venue['logo_url'] as String;
      final uri = Uri.parse(logoUrl);
      final segments = uri.pathSegments;

      final brandingIndex = segments.indexOf('branding');
      if (brandingIndex != -1 && brandingIndex + 1 < segments.length) {
        final path = segments.sublist(brandingIndex + 1).join('/');
        return await SupabaseService.client.storage.from('branding').download(path);
      }
    } catch (e) {
      AppLogger.error('Failed to fetch venue logo', e);
    }
    return null;
  }

  Future<String?> uploadReport(String path, Uint8List bytes) async {
    try {
      await SupabaseService.client.storage
          .from('reports')
          .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true));
      return path;
    } catch (e) {
      AppLogger.error('Failed to upload report bytes', e);
      return null;
    }
  }

  Future<void> saveReportMetadata({
    required String venueId,
    required String reportType,
    required DateTime generationDate,
    required String storagePath,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    await SupabaseService.client.from('generated_reports').insert({
      'venue_id': venueId,
      'report_type': reportType,
      'generation_date': generationDate.toIso8601String().split('T')[0],
      'created_by': userId,
      'storage_path': storagePath,
      'metadata': metadata ?? {},
    });
  }

  Future<Map<String, dynamic>?> getSavedReport(DateTime date, String type) async {
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      final response = await SupabaseService.client
          .from('generated_reports')
          .select()
          .eq('generation_date', dateStr)
          .eq('report_type', type)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      AppLogger.error('Failed to query saved report metadata', e);
      return null;
    }
  }

  Future<Uint8List?> downloadReport(String path) async {
    try {
      return await SupabaseService.client.storage.from('reports').download(path);
    } catch (e) {
      AppLogger.error('Failed to download report from storage', e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getGeneratedReports(String venueId) async {
    try {
      final response = await SupabaseService.client
          .from('generated_reports')
          .select()
          .eq('venue_id', venueId)
          .order('generation_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Failed to fetch generated reports list', e);
      return [];
    }
  }
}

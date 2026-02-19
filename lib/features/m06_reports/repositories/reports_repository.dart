
import 'package:flutter/foundation.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
// import 'package:http/http.dart' as http; // Use supabase storage download instead

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

  Future<List<Map<String, dynamic>>> getCoolingLogs(DateTime date) async {
    // Determine start and end of the day
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final response = await SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', 'gmp')
        .eq('form_id', 'food_cooling') // Specific filter for cooling logs
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getGmpLogs(DateTime start, DateTime end) async {
    // CORRECTED: Read from unified 'haccp_logs' table with category filter
    final response = await SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', 'gmp')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeasurements(DateTime start, DateTime end) async {
    // We join 'sensors' table to get the name.
    // The query '*, sensors(name)' fetches all measurement columns + sensor name.
    final response = await SupabaseService.client
        .from('temperature_logs')
        .select('*, sensors(name)')
        .gte('recorded_at', start.toIso8601String()) // Note: field is recorded_at, not timestamp
        .lte('recorded_at', end.toIso8601String())
        .order('recorded_at');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Helper to fetch logo bytes if available for a venue
  Future<Uint8List?> getVenueLogo(String venueId) async {
    try {
      final venue = await SupabaseService.client
          .from('venues')
          .select('logo_url')
          .eq('id', venueId)
          .maybeSingle();
      
      if (venue == null || venue['logo_url'] == null) return null;

      final logoUrl = venue['logo_url'] as String;
      // Extract path from public URL or store path directly?
      // If logo_url is full public URL: https://.../storage/v1/object/public/branding/logos/...
      // Supabase download needs the path relative to bucket.
      // Current upload implementation stores full URL in DB.
      // So we must download via HTTP or parse path. 
      // Supabase helper download() works on bucket paths.
      // Easier: Use http.get since it is a public URL.
      
      // Since we don't have http package imported in this file, let's use Supabase storage 
      // if we can extract the path.
      // URL format: .../branding/logos/venueId/timestamp.jpg
      
      final uri = Uri.parse(logoUrl);
      final segments = uri.pathSegments; 
      // segments usually: ['storage', 'v1', 'object', 'public', 'branding', 'logos', ...]
      // We want 'logos/...'
      
      final brandingIndex = segments.indexOf('branding');
      if (brandingIndex != -1 && brandingIndex + 1 < segments.length) {
         final path = segments.sublist(brandingIndex + 1).join('/');
         // path = 'logos/venueId/...'
         final bytes = await SupabaseService.client.storage.from('branding').download(path);
         return bytes;
      }
    } catch (e) {
      debugPrint('Error fetching logo: $e');
    }
    return null;
  }
  /// Uploads report bytes to Supabase Storage
  Future<String?> uploadReport(String path, Uint8List bytes) async {
    try {
      await SupabaseService.client.storage
          .from('reports')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      return path;
    } catch (e) {
      debugPrint('Error uploading report: $e');
      return null;
    }
  }

  /// Saves report metadata to the database
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

  /// Checks if a report already exists for the given date and type
  Future<Map<String, dynamic>?> getSavedReport(DateTime date, String type) async {
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      // We assume one report per type per day? Or latest?
      // Let's get the latest one.
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
      debugPrint('Error checking saved report: $e');
      return null;
    }
  }

  /// Downloads a report from storage
  Future<Uint8List?> downloadReport(String path) async {
    try {
      return await SupabaseService.client.storage.from('reports').download(path);
    } catch (e) {
      debugPrint('Error downloading report: $e');
      return null;
    }
  }
  /// Fetches list of generated reports for a venue
  Future<List<Map<String, dynamic>>> getGeneratedReports(String venueId) async {
    try {
      final response = await SupabaseService.client
          .from('generated_reports')
          .select()
          .eq('venue_id', venueId)
          .order('generation_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching generated reports: $e');
      return [];
    }
  }
}

import 'dart:typed_data';
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
}

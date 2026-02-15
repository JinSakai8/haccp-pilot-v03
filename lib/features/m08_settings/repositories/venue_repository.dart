import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';

class VenueRepository {
  final _client = SupabaseService.client;
  static const String _brandingBucket = 'branding';

  /// Fetches settings for a given venue.
  Future<Map<String, dynamic>?> getSettings(String venueId) async {
    final response = await _client
        .from('venues')
        .select('name, nip, address, logo_url, temp_interval, temp_threshold')
        .eq('id', venueId)
        .maybeSingle();
    return response;
  }

  /// Updates venue settings.
  Future<void> updateSettings({
    required String venueId,
    required String name,
    required String nip,
    required String address,
    String? logoUrl,
    int? tempInterval,
    double? tempThreshold,
  }) async {
    final updates = {
      'name': name,
      'nip': nip,
      'address': address,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (tempInterval != null) 'temp_interval': tempInterval,
      if (tempThreshold != null) 'temp_threshold': tempThreshold,
    };

    await _client.from('venues').update(updates).eq('id', venueId);
  }

  /// Uploads logo bytes to 'branding' bucket and returns the Public URL.
  Future<String?> uploadLogoBytes(Uint8List bytes, String venueId, String extension) async {
    try {
      final fileName = 'logos/$venueId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      await _client.storage.from(_brandingBucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = _client.storage.from(_brandingBucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Logo Upload Error: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
import 'package:haccp_pilot/core/services/storage_service.dart'; // Reusing existing storage logic or new one?
// StorageService is specific to Waste. I'll use direct SupabaseService logic or expand StorageService?
// I'll implement specific logic here for brevity and separation, or create a method in StorageService.
// Let's implement here for now, as logo is specific.

class VenueRepository {
  final _client = SupabaseService.client;
  static const String _brandingBucket = 'branding';

  /// Fetches settings for a given venue.
  Future<Map<String, dynamic>?> getSettings(String venueId) async {
    final response = await _client
        .from('venues')
        .select('name, nip, address, logo_url')
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
  }) async {
    final updates = {
      'name': name,
      'nip': nip,
      'address': address,
      if (logoUrl != null) 'logo_url': logoUrl,
    };

    await _client.from('venues').update(updates).eq('id', venueId);
  }

  /// Uploads a logo file to 'branding' bucket and returns the Public URL.
  Future<String?> uploadLogo(File file, String venueId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = 'logos/$venueId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // Upload
      await _client.storage.from(_brandingBucket).upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get Public URL
      final publicUrl = _client.storage.from(_brandingBucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Logo Upload Error: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class VenueRepository {
  final _client = SupabaseService.client;

  /// Fetches venue settings. 
  /// Since we are single-tenant per device/login usually, we might fetch by ID or first row.
  /// For now, fetching by [venueId].
  Future<Map<String, dynamic>?> getVenueSettings(String venueId) async {
    final response = await _client
        .from('venues')
        .select()
        .eq('id', venueId)
        .maybeSingle();
    return response;
  }

  /// Updates venue settings (name, nip, address).
  Future<void> updateVenueSettings(String venueId, {
    String? name,
    String? nip,
    String? address,
    String? logoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (nip != null) updates['nip'] = nip;
    if (address != null) updates['address'] = address;
    if (logoUrl != null) updates['logo_url'] = logoUrl;

    if (updates.isEmpty) return;

    await _client.from('venues').update(updates).eq('id', venueId);
  }

  /// Uploads logo to 'branding' bucket and returns public URL.
  Future<String> uploadLogo(File file, String venueId) async {
    final fileExt = file.path.split('.').last;
    final path = 'logos/$venueId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _client.storage.from('branding').upload(
      path, 
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from('branding').getPublicUrl(path);
  }
}

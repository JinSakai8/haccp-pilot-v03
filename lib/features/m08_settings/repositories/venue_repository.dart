import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';

enum M08SettingsErrorCode {
  dbConstraint,
  dbRlsDeny,
  storageDenyOrNotFound,
  unknown,
}

class M08SettingsException implements Exception {
  final M08SettingsErrorCode code;
  final String message;
  final Object? cause;

  const M08SettingsException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'M08SettingsException($code): $message';
}

class VenueRepository {
  final _client = SupabaseService.client;
  static const String _brandingBucket = 'branding';

  M08SettingsException _mapDbError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('check constraint') ||
        raw.contains('venues_temp_interval_check') ||
        raw.contains('venues_temp_threshold_check') ||
        raw.contains('venues_nip_digits_check') ||
        raw.contains('23514')) {
      return M08SettingsException(
        code: M08SettingsErrorCode.dbConstraint,
        message: 'M08_DB_CONSTRAINT',
        cause: error,
      );
    }
    if (raw.contains('row-level security') ||
        raw.contains('permission denied') ||
        raw.contains('42501')) {
      return M08SettingsException(
        code: M08SettingsErrorCode.dbRlsDeny,
        message: 'M08_DB_RLS_DENY',
        cause: error,
      );
    }
    return M08SettingsException(
      code: M08SettingsErrorCode.unknown,
      message: 'M08_DB_UNKNOWN',
      cause: error,
    );
  }

  M08SettingsException _mapStorageError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('row-level security') ||
        raw.contains('permission denied') ||
        raw.contains('not found') ||
        raw.contains('bucket')) {
      return M08SettingsException(
        code: M08SettingsErrorCode.storageDenyOrNotFound,
        message: 'M08_STORAGE_DENY_OR_NOT_FOUND',
        cause: error,
      );
    }
    return M08SettingsException(
      code: M08SettingsErrorCode.unknown,
      message: 'M08_STORAGE_UNKNOWN',
      cause: error,
    );
  }

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
    required String? nip,
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

    try {
      await _client.from('venues').update(updates).eq('id', venueId);
    } catch (e) {
      throw _mapDbError(e);
    }
  }

  /// Uploads logo bytes to 'branding' bucket and returns the Public URL.
  Future<String> uploadLogoBytes(
    Uint8List bytes,
    String venueId,
    String extension,
  ) async {
    try {
      final fileName =
          'logos/$venueId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from(_brandingBucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = _client.storage
          .from(_brandingBucket)
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Logo Upload Error: $e');
      throw _mapStorageError(e);
    }
  }
}

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();
  
  static const String _wasteBucket = 'waste-docs';

  /// Uploads a waste photo to Supabase Storage.
  /// 
  /// [imageBytes] - The image bytes to upload.
  /// [venueId] - The venue ID for folder organization.
  /// 
  /// Returns the storage path of the uploaded file.
  static Future<String?> uploadWastePhotoBytes(Uint8List imageBytes, String venueId) async {
    try {
      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final timestamp = now.millisecondsSinceEpoch;
      final fileName = '${timestamp}_waste.jpg';
      final storagePath = '$venueId/$year/$month/$day/$fileName';

      await SupabaseService.storage.from(_wasteBucket).uploadBinary(
        storagePath,
        imageBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      return storagePath; 
      
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }
  
  /// Helper to get viewable URL
  static Future<String> getSignedUrl(String path) async {
    return await SupabaseService.storage.from(_wasteBucket).createSignedUrl(path, 60 * 60);
  }
}


import 'dart:io';
import 'package:haccp_pilot/core/services/storage_service.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
import '../models/waste_record.dart';

class WasteRepository {
  final _table = 'waste_records';

  Future<void> insertRecord(WasteRecord record) async {
    await SupabaseService.client.from(_table).insert({
      'venue_id': record.venueId,
      'zone_id': record.zoneId,
      'user_id': record.userId,
      'waste_type': record.wasteType,
      'waste_code': record.wasteCode,
      'mass_kg': record.massKg,
      'recipient_company': record.recipientCompany,
      'kpo_number': record.kpoNumber,
      'photo_url': record.photoUrl,
    });
  }

  Future<String?> uploadPhoto(File file, String venueId) async {
    return await StorageService.uploadWastePhoto(file, venueId);
  }

  Future<List<WasteRecord>> getRecentRecords(String venueId) async {
    final response = await SupabaseService.client
        .from(_table)
        .select()
        .eq('venue_id', venueId)
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List).map((e) => WasteRecord.fromJson(e)).toList();
  }

  Future<List<WasteRecord>> getHistory(String venueId, {DateTime? fromDate, DateTime? toDate}) async {
    var query = SupabaseService.client
        .from(_table)
        .select()
        .eq('venue_id', venueId);

    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => WasteRecord.fromJson(e)).toList();
  }
}

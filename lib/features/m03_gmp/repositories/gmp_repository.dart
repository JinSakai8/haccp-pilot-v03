import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

class GmpRepository {
  final _client = SupabaseService.client;
  final String _table = 'haccp_logs';

  Future<void> insertLog({
    required String formId,
    required Map<String, dynamic> data,
    required String userId,
    required String zoneId,
    String? venueId,
  }) async {
    debugPrint('🔵 GmpRepository.insertLog: formId=$formId, category=gmp, zoneId=$zoneId, venueId=$venueId');
    debugPrint('🔵 GmpRepository.insertLog: data keys=${data.keys.toList()}');
    await _client.from(_table).insert({
      'category': 'gmp',
      'form_id': formId,
      'data': data,
      'user_id': userId,
      'zone_id': zoneId,
      if (venueId != null) 'venue_id': venueId,
      'created_at': DateTime.now().toIso8601String(),
    });
    debugPrint('🟢 GmpRepository.insertLog: SUCCESS');
  }

  Future<List<Map<String, dynamic>>> getHistory(String zoneId, {
    DateTime? fromDate,
    DateTime? toDate,
    String? formId,
  }) async {
    var query = _client
        .from(_table)
        .select()
        .eq('category', 'gmp')
        .eq('zone_id', zoneId);

    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }
    if (formId != null) {
       // Allow partial match if needed, but exact match is safer for now
       query = query.eq('form_id', formId);
    }
        
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

final gmpRepositoryProvider = Provider<GmpRepository>((ref) => GmpRepository());

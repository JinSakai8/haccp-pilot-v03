import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

class GhpRepository {
  final _client = SupabaseService.client;
  final String _table = 'haccp_logs';

  Future<void> insertChecklist({
    required String formId,
    required Map<String, dynamic> data,
    required String userId,
    required String zoneId,
    String? venueId,
  }) async {
    await _client.from(_table).insert({
      'category': 'ghp',
      'form_id': formId,
      'data': data,
      'user_id': userId,
      'zone_id': zoneId,
      if (venueId != null) 'venue_id': venueId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(String zoneId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('category', 'ghp')
        .eq('zone_id', zoneId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

final ghpRepositoryProvider = Provider<GhpRepository>((ref) => GhpRepository());

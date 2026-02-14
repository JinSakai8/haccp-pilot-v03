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
  }) async {
    await _client.from(_table).insert({
      'category': 'gmp',
      'form_id': formId,
      'data': data,
      'user_id': userId,
      'zone_id': zoneId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(String zoneId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('category', 'gmp')
        .eq('zone_id', zoneId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

final gmpRepositoryProvider = Provider<GmpRepository>((ref) => GmpRepository());

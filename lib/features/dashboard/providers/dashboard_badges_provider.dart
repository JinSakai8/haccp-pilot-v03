import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';

part 'dashboard_badges_provider.g.dart';

@riverpod
class DashboardBadges extends _$DashboardBadges {
  @override
  Future<Map<String, String?>> build() async {
    // Refresh badges every 60 seconds or on demand
    // timer = Timer.periodic(...) - usually better to use ref.invalidate self externally
    return _fetchBadges();
  }

  Future<Map<String, String?>> _fetchBadges() async {
    final supabase = Supabase.instance.client;
    final zone = ref.read(currentZoneProvider);
    
    // Default empty state
    final badges = <String, String?>{
      'monitoring': null,
      'gmp': null,
      'ghp': null,
      'waste': null,
      'reports': null,
      'hr': null,
    };

    if (zone == null) return badges;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // 1. Monitoringu (Active Alarms)
      // Assuming 'measurements' has 'is_alarm' = true and 'is_acknowledged' = false
      // OR specific alarm logic. For now, let's just count 'measurements' > 25 degrees as a demo if no alarm table
      // Real implementation should check `active_alarms` view or table
      // final activeAlarms = await supabase
      //     .from('measurements')
      //     .count(CountOption.exact)
      //     .eq('zone_id', zone.id)
      //     .gt('temperature', 10.0); // Simple threshold for demo logic
      // if (activeAlarms.count > 0) badges['monitoring'] = '${activeAlarms.count}';

      // 2. GMP (Today's logs)
      final gmpCount = await supabase
          .from('haccp_logs')
          .count(CountOption.exact)
          .eq('zone_id', zone.id)
          .eq('category', 'gmp')
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);
      
      
      if (gmpCount > 0) badges['gmp'] = '$gmpCount';

      // 3. Waste (Today's logs)
      final wasteCount = await supabase
          .from('waste_records')
          .count(CountOption.exact)
          .eq('venue_id', zone.venueId) // Waste is usually venue-wide
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);
      
      if (wasteCount > 0) badges['waste'] = '$wasteCount';

      // 4. HR (Expiring Sanepid)
      // Only for managers
      final employee = ref.read(currentUserProvider);
      if (employee != null && employee.isManager) {
         final expiringCount = await supabase
          .from('employees')
          .count(CountOption.exact)
          .lt('sanepid_expiry', now.add(const Duration(days: 7)).toIso8601String()); // Expiring in 7 days
         
         if (expiringCount > 0) badges['hr'] = '$expiringCount';
      }

    } catch (e) {
      // badge fetch error, just return empty
      print('Badge fetch error: $e');
    }

    return badges;
  }
}

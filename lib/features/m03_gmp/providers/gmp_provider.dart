import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/gmp_repository.dart';
import '../../../core/providers/auth_provider.dart';

import '../../../core/models/zone.dart';

part 'gmp_provider.g.dart';

@riverpod
class GmpFormSubmission extends _$GmpFormSubmission {
  @override
  FutureOr<void> build() {
    // Initial state is idle (null or void)
  }

  Future<bool> submitLog({
    required String formId,
    required Map<String, dynamic> data,
  }) async {
    state = const AsyncLoading();
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = AsyncError('Brak zalogowanego użytkownika', StackTrace.current);
      return false;
    }

    // Resolve Zone and Venue
    String zoneId = 'default_zone';
    String? venueId;

    final currentZone = ref.read(currentZoneProvider);
    if (currentZone != null) {
      zoneId = currentZone.id;
      venueId = currentZone.venueId;
    } else {
      // Fallback: Try to get from employee zones
      try {
        final zones = await ref.read(employeeZonesProvider.future);
        if (zones.isNotEmpty) {
          final firstZone = zones.first;
          zoneId = firstZone.id;
          venueId = firstZone.venueId;
        } else if (currentUser.zones.isNotEmpty) {
          // Last resort: we have ID but no venue info
          zoneId = currentUser.zones.first;
        }
      } catch (e) {
        // If getting zones fails, use what we have in user profile
        if (currentUser.zones.isNotEmpty) {
          zoneId = currentUser.zones.first;
        }
      }
    }

    state = await AsyncValue.guard(() async {
      final repository = ref.read(gmpRepositoryProvider);
      await repository.insertLog(
        formId: formId,
        data: data,
        userId: currentUser.id,
        zoneId: zoneId,
        venueId: venueId,
      );
    });

    return !state.hasError;
  }
}

@riverpod
Future<List<Map<String, dynamic>>> gmpHistory(
  Ref ref, {
  DateTime? fromDate,
  DateTime? toDate,
  String? formId,
}) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  
  final zoneId = ref.watch(currentZoneProvider)?.id ?? 
                 (user.zones.isNotEmpty ? user.zones.first : 'default_zone');
                 
  return ref.watch(gmpRepositoryProvider).getHistory(
        zoneId,
        fromDate: fromDate,
        toDate: toDate,
        formId: formId,
      );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import '../repositories/ghp_repository.dart';
import '../../../core/providers/auth_provider.dart';

import '../../../core/models/zone.dart';

part 'ghp_provider.g.dart';

@riverpod
class GhpFormSubmission extends _$GhpFormSubmission {
  @override
  Future<void> build() async {}

  Future<bool> submitChecklist({
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
      final repository = ref.read(ghpRepositoryProvider);
      await repository.insertChecklist(
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
Future<List<Map<String, dynamic>>> ghpHistory(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  
  final zoneId = ref.watch(currentZoneProvider)?.id ?? 
                 (user.zones.isNotEmpty ? user.zones.first : 'default_zone');
                 
  return ref.watch(ghpRepositoryProvider).getHistory(zoneId);
}

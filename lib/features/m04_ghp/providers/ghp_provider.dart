import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import '../repositories/ghp_repository.dart';
import '../../../core/providers/auth_provider.dart';

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

    final zoneId = ref.read(currentZoneProvider)?.id ?? 
                   (currentUser.zones.isNotEmpty ? currentUser.zones.first : 'default_zone');

    state = await AsyncValue.guard(() async {
      final repository = ref.read(ghpRepositoryProvider);
      await repository.insertChecklist(
        formId: formId,
        data: data,
        userId: currentUser.id,
        zoneId: zoneId,
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

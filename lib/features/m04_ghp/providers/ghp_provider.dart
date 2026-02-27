import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/ghp_repository.dart';
import '../../../core/providers/auth_provider.dart';

part 'ghp_provider.g.dart';

@visibleForTesting
Map<String, dynamic> normalizeGhpSubmissionData(
  Map<String, dynamic> data, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final executionDate =
      '${clock.year.toString().padLeft(4, '0')}-${clock.month.toString().padLeft(2, '0')}-${clock.day.toString().padLeft(2, '0')}';
  final executionTime =
      '${clock.hour.toString().padLeft(2, '0')}:${clock.minute.toString().padLeft(2, '0')}';

  final existingAnswers = data['answers'];
  final normalizedAnswers = existingAnswers is Map
      ? Map<String, dynamic>.from(existingAnswers)
      : Map<String, dynamic>.from(data);

  return <String, dynamic>{
    'execution_date': data['execution_date']?.toString() ?? executionDate,
    'execution_time': data['execution_time']?.toString() ?? executionTime,
    'answers': normalizedAnswers,
    if (data['notes'] != null && data['notes'].toString().trim().isNotEmpty)
      'notes': data['notes'].toString().trim(),
  };
}

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

    final currentZone = ref.read(currentZoneProvider);
    if (currentZone == null) {
      state = AsyncError(
        'Brak aktywnej strefy. Wybierz strefe ponownie.',
        StackTrace.current,
      );
      return false;
    }

    final normalizedData = normalizeGhpSubmissionData(data);

    state = await AsyncValue.guard(() async {
      final repository = ref.read(ghpRepositoryProvider);
      await repository.insertChecklist(
        formId: formId,
        data: normalizedData,
        userId: currentUser.id,
        zoneId: currentZone.id,
        venueId: currentZone.venueId,
      );
    });

    return !state.hasError;
  }
}

@riverpod
Future<List<Map<String, dynamic>>> ghpHistory(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);

  final currentZone = ref.watch(currentZoneProvider);
  if (currentZone == null) return Future.value([]);

  return ref.watch(ghpRepositoryProvider).getHistory(currentZone.id);
}

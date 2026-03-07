import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/gmp_repository.dart';
import '../../../core/providers/auth_provider.dart';

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

    final currentZone = ref.read(currentZoneProvider);
    if (currentZone == null) {
      state = AsyncError(
        'Brak aktywnej strefy. Wybierz strefę ponownie.',
        StackTrace.current,
      );
      return false;
    }

    state = await AsyncValue.guard(() async {
      final repository = ref.read(gmpRepositoryProvider);
      await repository.insertLog(
        formId: formId,
        data: data,
        userId: currentUser.id,
        zoneId: currentZone.id,
        venueId: currentZone.venueId,
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

  final currentZone = ref.watch(currentZoneProvider);
  if (currentZone == null) return Future.value([]);

  return ref
      .watch(gmpRepositoryProvider)
      .getHistory(
        currentZone.id,
        fromDate: fromDate,
        toDate: toDate,
        formId: formId,
      );
}

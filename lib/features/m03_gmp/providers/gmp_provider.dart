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

    final zoneId = ref.read(currentZoneProvider)?.id ?? 
                   (currentUser.zones.isNotEmpty ? currentUser.zones.first : 'default_zone');

    state = await AsyncValue.guard(() async {
      final repository = ref.read(gmpRepositoryProvider);
      await repository.insertLog(
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

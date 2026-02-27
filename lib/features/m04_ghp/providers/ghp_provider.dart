import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/ghp_repository.dart';
import '../../../core/providers/auth_provider.dart';
import '../../m07_hr/providers/hr_provider.dart';
import '../../shared/repositories/products_repository.dart';

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

@visibleForTesting
Map<String, dynamic> applyGhpReferenceSnapshots({
  required Map<String, dynamic> answers,
  String? employeeId,
  String? employeeName,
  String? roomId,
  String? roomName,
}) {
  final mapped = Map<String, dynamic>.from(answers);

  if (employeeId != null && employeeId.isNotEmpty) {
    final normalizedName = (employeeName ?? '').trim();
    mapped['selected_employee'] = {
      'id': employeeId,
      'name': normalizedName.isEmpty ? employeeId : normalizedName,
    };
  }

  if (roomId != null && roomId.isNotEmpty) {
    final normalizedName = (roomName ?? '').trim();
    mapped['selected_room'] = {
      'id': roomId,
      'name': normalizedName.isEmpty ? roomId : normalizedName,
    };
  }

  return mapped;
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
    final enrichedData = await _enrichAnswersWithSnapshots(
      formId: formId,
      normalizedData: normalizedData,
      venueId: currentZone.venueId,
    );

    state = await AsyncValue.guard(() async {
      final repository = ref.read(ghpRepositoryProvider);
      await repository.insertChecklist(
        formId: formId,
        data: enrichedData,
        userId: currentUser.id,
        zoneId: currentZone.id,
        venueId: currentZone.venueId,
      );
    });

  return !state.hasError;
  }

  Future<Map<String, dynamic>> _enrichAnswersWithSnapshots({
    required String formId,
    required Map<String, dynamic> normalizedData,
    required String venueId,
  }) async {
    final answers = Map<String, dynamic>.from(
      normalizedData['answers'] as Map<String, dynamic>? ?? const {},
    );

    String? selectedEmployeeId;
    String? selectedEmployeeName;
    String? selectedRoomId;
    String? selectedRoomName;

    if (formId.contains('personnel')) {
      final rawEmployee = answers['selected_employee'];
      if (rawEmployee is String && rawEmployee.trim().isNotEmpty) {
        selectedEmployeeId = rawEmployee.trim();

        final employees = await ref.read(hrRepositoryProvider).getEmployees();
        for (final employee in employees) {
          if (employee.id == selectedEmployeeId) {
            selectedEmployeeName = employee.fullName;
            break;
          }
        }
      }
    }

    if (formId.contains('rooms')) {
      final rawRoom = answers['selected_room'];
      if (rawRoom is String && rawRoom.trim().isNotEmpty) {
        selectedRoomId = rawRoom.trim();

        final rooms = await ref
            .read(productsRepositoryProvider)
            .getProducts('rooms', venueId: venueId);
        for (final room in rooms) {
          if (room.id == selectedRoomId) {
            selectedRoomName = room.name;
            break;
          }
        }
      }
    }

    return <String, dynamic>{
      ...normalizedData,
      'answers': applyGhpReferenceSnapshots(
        answers: answers,
        employeeId: selectedEmployeeId,
        employeeName: selectedEmployeeName,
        roomId: selectedRoomId,
        roomName: selectedRoomName,
      ),
    };
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

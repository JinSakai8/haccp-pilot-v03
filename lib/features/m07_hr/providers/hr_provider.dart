import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/employee.dart';
import '../../../core/models/zone.dart';
import '../repositories/hr_repository.dart';

part 'hr_provider.g.dart';

/// Provider for HR Repository
@riverpod
HrRepository hrRepository(Ref ref) {
  return HrRepository();
}

/// Provider to fetch all employees
@riverpod
Future<List<Employee>> hrEmployees(Ref ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return repository.getEmployees();
}

/// Provider to fetch available zones
@riverpod
Future<List<Zone>> hrZones(Ref ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return repository.getZones();
}

/// AsyncNotifier for HR actions (create, update, delete)
@riverpod
class HrController extends _$HrController {
  @override
  Future<void> build() async {
    // No initial state
  }

  Future<bool> checkPinUnique(String pin) async {
    final repository = ref.read(hrRepositoryProvider);
    return repository.checkPinUnique(pin);
  }

  Future<void> createEmployee({
    required String fullName,
    required String pin,
    required String role,
    required DateTime? sanepidExpiry,
    required List<String> zoneIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hrRepositoryProvider);
      final employee = Employee(
        id: '',
        fullName: fullName,
        role: role,
        isActive: true,
        sanepidExpiry: sanepidExpiry,
        zones: zoneIds, // Optional based on model, but useful for local state
      );
      await repository.createEmployee(employee, pin, zoneIds);
      ref.invalidate(hrEmployeesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSanepid(String employeeId, DateTime newDate) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hrRepositoryProvider);
      await repository.updateSanepid(employeeId, newDate);
      ref.invalidate(hrEmployeesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleActive(String employeeId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hrRepositoryProvider);
      await repository.toggleActive(employeeId, isActive);
      ref.invalidate(hrEmployeesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  Future<void> updatePin(String employeeId, String newPin) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hrRepositoryProvider);
      await repository.updatePin(employeeId, newPin);
      // No need to invalidate employees list as PIN is not returned
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

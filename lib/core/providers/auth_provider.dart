import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import '../models/zone.dart';
import '../repositories/auth_repository.dart';

// ─── Repository ───────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ─── Global State (kept alive — Kiosk Mode) ───────────────────

class CurrentEmployeeNotifier extends Notifier<Employee?> {
  @override
  Employee? build() => null;

  void set(Employee? employee) => state = employee;
  void clear() => state = null;
}

final currentEmployeeProvider =
    NotifierProvider<CurrentEmployeeNotifier, Employee?>(
        CurrentEmployeeNotifier.new);

class CurrentZoneNotifier extends Notifier<Zone?> {
  @override
  Zone? build() => null;

  void set(Zone? zone) => state = zone;
  void clear() => state = null;
}

final currentZoneProvider =
    NotifierProvider<CurrentZoneNotifier, Zone?>(CurrentZoneNotifier.new);

// ─── PIN Login State Machine ──────────────────────────────────
enum LoginStatus { idle, loading, success, error }

class PinLoginNotifier extends Notifier<LoginStatus> {
  @override
  LoginStatus build() => LoginStatus.idle;

  /// Attempts login. Returns [Employee] on success, null on failure.
  /// Sets [LoginStatus.error] which auto-resets after 3 seconds.
  Future<Employee?> login(String pin) async {
    state = LoginStatus.loading;
    try {
      final repository = ref.read(authRepositoryProvider);
      final employee = await repository.loginWithPin(pin);

      if (employee != null) {
        ref.read(currentEmployeeProvider.notifier).set(employee);
        state = LoginStatus.success;
        return employee;
      } else {
        state = LoginStatus.error;
        Future.delayed(const Duration(seconds: 3), () {
          if (state == LoginStatus.error) {
            state = LoginStatus.idle;
          }
        });
        return null;
      }
    } catch (e) {
      state = LoginStatus.error;
      Future.delayed(const Duration(seconds: 3), () {
        if (state == LoginStatus.error) {
          state = LoginStatus.idle;
        }
      });
      return null;
    }
  }

  void reset() => state = LoginStatus.idle;
}

final pinLoginProvider =
    NotifierProvider<PinLoginNotifier, LoginStatus>(PinLoginNotifier.new);

// ─── Zones for Current Employee (autoDispose) ─────────────────
final employeeZonesProvider =
    FutureProvider.autoDispose<List<Zone>>((ref) async {
  final employee = ref.watch(currentEmployeeProvider);
  if (employee == null) return [];
  return ref.read(authRepositoryProvider).getZonesForEmployee(employee.id);
});

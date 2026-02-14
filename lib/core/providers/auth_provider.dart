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

final currentUserProvider =
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
enum LoginStatus { idle, loading, success, error, locked }

class PinLoginNotifier extends Notifier<LoginStatus> {
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  LoginStatus build() => LoginStatus.idle;

  DateTime? get lockoutUntil => _lockoutUntil;

  /// Attempts login. Returns [Employee] on success, null on failure.
  Future<Employee?> login(String pin) async {
    // 1. Check if locked
    if (_lockoutUntil != null) {
      if (DateTime.now().isBefore(_lockoutUntil!)) {
        state = LoginStatus.locked;
        return null;
      } else {
        // Lockout expired
        _lockoutUntil = null;
        // Don't reset _failedAttempts here to maintain "strict mode" (one fail = lock again)
        // or reset? Let's reset to give user a chance.
        _failedAttempts = 0; 
        state = LoginStatus.idle;
      }
    }

    state = LoginStatus.loading;
    try {
      final repository = ref.read(authRepositoryProvider);
      final employee = await repository.loginWithPin(pin);

      if (employee != null) {
        // Success
        _failedAttempts = 0;
        _lockoutUntil = null;
        ref.read(currentUserProvider.notifier).set(employee);
        state = LoginStatus.success;
        return employee;
      } else {
        // Failure
        _failedAttempts++;
        _handleLockout();
        
        // Only show error if not locked
        if (state != LoginStatus.locked) {
          state = LoginStatus.error;
          Future.delayed(const Duration(seconds: 3), () {
            if (state == LoginStatus.error) {
              state = LoginStatus.idle;
            }
          });
        }
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

  void _handleLockout() {
    Duration? lockoutDuration;
    
    // Progressive lockout
    if (_failedAttempts >= 20) {
      lockoutDuration = const Duration(minutes: 30);
    } else if (_failedAttempts >= 10) {
      lockoutDuration = const Duration(minutes: 5);
    } else if (_failedAttempts >= 5) {
      lockoutDuration = const Duration(seconds: 30);
    }

    if (lockoutDuration != null) {
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      state = LoginStatus.locked;
      
      // Auto-reset after duration
      Future.delayed(lockoutDuration, () {
        if (state == LoginStatus.locked) {
          state = LoginStatus.idle;
          _lockoutUntil = null;
          // _failedAttempts stays high? No, reset on expiry to match simple logic
          _failedAttempts = 0; 
        }
      });
    }
  }

  void reset() {
     if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
       return; // Don't reset manually if locked
     }
     state = LoginStatus.idle;
  }
}

final pinLoginProvider =
    NotifierProvider<PinLoginNotifier, LoginStatus>(PinLoginNotifier.new);

// ─── Zones for Current Employee (autoDispose) ─────────────────
final employeeZonesProvider =
    FutureProvider.autoDispose<List<Zone>>((ref) async {
  final employee = ref.watch(currentUserProvider);
  if (employee == null) return [];
  return ref.read(authRepositoryProvider).getZonesForEmployee(employee.id);
});

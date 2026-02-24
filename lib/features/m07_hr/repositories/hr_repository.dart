import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/employee.dart';
import '../../../core/models/zone.dart';
import '../../../../core/services/supabase_service.dart';

class HrRepositoryException implements Exception {
  final String code;
  final String message;

  const HrRepositoryException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

class HrRepository {
  final _client = SupabaseService.client;

  /// Hashes PIN with SHA-256 (matches format stored in DB).
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Never _throwMappedException(PostgrestException e) {
    final normalized = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
        .toUpperCase();

    if (normalized.contains('M07_PIN_DUPLICATE')) {
      throw const HrRepositoryException(
        code: 'M07_PIN_DUPLICATE',
        message: 'PIN jest juz zajety. Wybierz inny kod.',
      );
    }
    if (normalized.contains('M07_ZONE_REQUIRED')) {
      throw const HrRepositoryException(
        code: 'M07_ZONE_REQUIRED',
        message: 'Przypisz co najmniej jedna strefe.',
      );
    }
    if (normalized.contains('M07_ZONE_NOT_FOUND')) {
      throw const HrRepositoryException(
        code: 'M07_ZONE_NOT_FOUND',
        message: 'Wybrane strefy nie istnieja w bazie danych.',
      );
    }
    if (normalized.contains('M07_ZONE_MULTI_VENUE')) {
      throw const HrRepositoryException(
        code: 'M07_ZONE_MULTI_VENUE',
        message: 'Nie mozna przypisac stref z roznych lokali.',
      );
    }
    if (normalized.contains('M07_EMPLOYEE_NOT_FOUND')) {
      throw const HrRepositoryException(
        code: 'M07_EMPLOYEE_NOT_FOUND',
        message: 'Nie znaleziono pracownika do aktualizacji PIN.',
      );
    }
    if (normalized.contains('M07_PIN_REQUIRED')) {
      throw const HrRepositoryException(
        code: 'M07_PIN_REQUIRED',
        message: 'PIN jest wymagany.',
      );
    }

    throw HrRepositoryException(
      code: 'M07_UNKNOWN',
      message: 'Operacja HR nie powiodla sie: ${e.message}',
    );
  }

  /// Checks if a PIN is unique (Pre-check).
  /// Returns true if PIN is unique (available), false if taken.
  Future<bool> checkPinUnique(String pin) async {
    final hashedPin = _hashPin(pin);
    
    // Use RPC to check availability (bypassing RLS)
    final isAvailable = await _client.rpc('check_pin_availability', params: {
      'pin_input': hashedPin,
    });
    
    return isAvailable as bool;
  }

  /// Fetches all employees.
  /// Start filters can be applied on the client side or added here as params.
  Future<List<Employee>> getEmployees() async {
    final response = await _client
        .from('public_employees')
        .select()
        .order('full_name', ascending: true);

    return (response as List).map((json) => Employee.fromJson(json)).toList();
  }

  /// Fetches available zones (for dropdown).
  Future<List<Zone>> getZones() async {
    // Assuming 'zones' table is readable by anon/auth (via RLS or public)
    // If not, we might need an RPC, but zones are usually public metadata.
    final response = await _client
        .from('zones')
        .select()
        .order('name', ascending: true);
        
    return (response as List).map((json) => Zone.fromJson(json)).toList();
  }

  /// Creates a new employee with assigned zones.
  Future<void> createEmployee(Employee employee, String pin, List<String> zoneIds) async {
    final hashedPin = _hashPin(pin);

    try {
      // Use RPC to create employee (bypassing RLS)
      await _client.rpc('create_employee', params: {
        'name_input': employee.fullName,
        'pin_hash_input': hashedPin,
        'role_input': employee.role,
        'sanepid_input': employee.sanepidExpiry?.toIso8601String(),
        'zone_ids_input': zoneIds, // Pass List<String> which maps to uuid[]
        'is_active_input': employee.isActive,
      });
    } on PostgrestException catch (e) {
      _throwMappedException(e);
    }
  }

  /// Updates Sanepid expiry date for an employee.
  Future<void> updateSanepid(String employeeId, DateTime newDate) async {
    // Use RPC to update (bypassing RLS)
    await _client.rpc('update_employee_sanepid', params: {
      'employee_id': employeeId,
      'new_expiry': newDate.toIso8601String(),
    });
  }

  /// Toggles employee active status.
  Future<void> toggleActive(String employeeId, bool isActive) async {
    // Use RPC to update (bypassing RLS)
    await _client.rpc('toggle_employee_active', params: {
      'employee_id': employeeId,
      'new_status': isActive,
    });
  }

  Future<void> updatePin(String employeeId, String newPin) async {
    final hashedPin = _hashPin(newPin);
    try {
      await _client.rpc('update_employee_pin', params: {
        'employee_id': employeeId,
        'new_pin_hash': hashedPin,
      });
    } on PostgrestException catch (e) {
      _throwMappedException(e);
    }
  }
}

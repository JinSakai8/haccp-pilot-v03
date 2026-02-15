import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../core/models/employee.dart';
import '../../../core/models/zone.dart';
import '../../../../core/services/supabase_service.dart';

class HrRepository {
  final _client = SupabaseService.client;

  /// Hashes PIN with SHA-256 (matches format stored in DB).
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
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
    
    // Use RPC to create employee (bypassing RLS)
    await _client.rpc('create_employee', params: {
      'name_input': employee.fullName,
      'pin_hash_input': hashedPin,
      'role_input': employee.role,
      'sanepid_input': employee.sanepidExpiry?.toIso8601String(),
      'zone_ids_input': zoneIds, // Pass List<String> which maps to uuid[]
      'is_active_input': employee.isActive,
    });
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
    // Note: If updatePin is needed, we should also create an RPC for it.
    // For now, leaving as direct update (might fail if RLS triggers).
    // Given the task scope was "Adding Employees", I'll focus on that.
    // But logically, this should also be an RPC if used by admins.
    await _client.from('employees').update({
      'pin_hash': hashedPin,
    }).eq('id', employeeId);
  }
}

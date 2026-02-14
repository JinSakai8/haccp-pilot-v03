import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../core/models/employee.dart';
import '../../core/services/supabase_service.dart';

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
    final response = await _client
        .from('employees')
        .select('id')
        .eq('pin_hash', hashedPin)
        .maybeSingle();
    
    return response == null;
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

  /// Creates a new employee.
  Future<void> createEmployee(Employee employee, String pin) async {
    final hashedPin = _hashPin(pin);
    
    await _client.from('employees').insert({
      'full_name': employee.fullName,
      'pin_hash': hashedPin,
      'role': employee.role,
      'is_active': employee.isActive,
      'sanepid_expiry': employee.sanepidExpiry?.toIso8601String(),
      // Add venue_id if needed, assuming it's handled via employee_zones or profile triggers
    });
  }

  /// Updates Sanepid expiry date for an employee.
  Future<void> updateSanepid(String employeeId, DateTime newDate) async {
    await _client.from('employees').update({
      'sanepid_expiry': newDate.toIso8601String(),
    }).eq('id', employeeId);
  }

  /// Toggles employee active status.
  Future<void> toggleActive(String employeeId, bool isActive) async {
    await _client.from('employees').update({
      'is_active': isActive,
    }).eq('id', employeeId);
  }
}

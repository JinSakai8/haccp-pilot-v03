import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/employee.dart';
import '../models/zone.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final _client = SupabaseService.client;

  /// Hashes PIN with SHA-256 (matches format stored in DB).
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  /// Attempts login by matching hashed PIN against the `employees` table.
  /// Returns [Employee] on success, null on failure.
  Future<Employee?> loginWithPin(String pin) async {
    final hashedPin = _hashPin(pin);
    final response = await _client
        .from('employees')
        .select('id, full_name, role, is_active, sanepid_expiry')
        .eq('pin_hash', hashedPin)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Employee.fromJson(response);
  }

  /// Fetches zones assigned to [employeeId] via the junction table.
  Future<List<Zone>> getZonesForEmployee(String employeeId) async {
    final response = await _client
        .from('employee_zones')
        .select('zones(id, name, venue_id)')
        .eq('employee_id', employeeId);

    return (response as List).map((row) {
      final zoneData = row['zones'] as Map<String, dynamic>;
      return Zone.fromJson(zoneData);
    }).toList();
  }
}

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

  /// Attempts login by matching hashed PIN via secure RPC (bypassing RLS).
  /// Returns [Employee] on success, null on failure.
  Future<Employee?> loginWithPin(String pin) async {
    final hashedPin = _hashPin(pin);
    
    // Directive 12: Use RPC to bypass RLS for login
    try {
      final response = await _client.rpc(
        'login_with_pin',
        params: {'pin_input': hashedPin},
      );

      // RPC returns a List (SETOF employees) or null/empty list
      final List<dynamic> data = response as List<dynamic>;
      
      if (data.isEmpty) return null;
      
      // We expect a single user, but take the first one if multiple (should be unique)
      return Employee.fromJson(data.first);
    } catch (e) {
      // Handle RPC errors (e.g. function not found) or network issues
      // In production, we might want to log this.
      print('Login Error: $e');
      return null;
    }
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

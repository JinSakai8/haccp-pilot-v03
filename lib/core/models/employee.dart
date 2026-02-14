class Employee {
  final String id;
  final String fullName;
  final String role; // owner, manager, cook, cleaner
  final bool isActive;
  final DateTime? sanepidExpiry;
  final List<String> zones;

  Employee({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.sanepidExpiry,
    this.zones = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      sanepidExpiry: json['sanepid_expiry'] != null
          ? DateTime.parse(json['sanepid_expiry'] as String)
          : null,
      zones: json['zones'] != null 
          ? (json['zones'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }

  bool get isManager => role == 'manager' || role == 'owner';

  // Alias for compatibility with older code expecting 'venues'
  List<String> get venues => zones;
}

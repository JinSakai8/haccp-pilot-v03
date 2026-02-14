class Employee {
  final String id;
  final String fullName;
  final String role; // owner, manager, cook, cleaner
  final bool isActive;
  final DateTime? sanepidExpiry;

  Employee({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.sanepidExpiry,
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
    );
  }

  bool get isManager => role == 'manager' || role == 'owner';
}

class Employee {
  final String id;
  final String fullName;
  final String pinHash;
  final String role; // owner, manager, cook, cleaner
  final bool isActive;

  Employee({
    required this.id,
    required this.fullName,
    required this.pinHash,
    required this.role,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      pinHash: json['pin_hash'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  bool get isManager => role == 'manager' || role == 'owner';
}

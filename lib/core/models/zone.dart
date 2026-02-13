class Zone {
  final String id;
  final String name;

  Zone({required this.id, required this.name});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

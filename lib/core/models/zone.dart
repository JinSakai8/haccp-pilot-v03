class Zone {
  final String id;
  final String name;
  final String venueId;

  Zone({required this.id, required this.name, required this.venueId});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String,
      name: json['name'] as String,
      venueId: json['venue_id'] as String,
    );
  }
}

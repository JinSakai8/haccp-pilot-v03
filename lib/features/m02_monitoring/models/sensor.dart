class Sensor {
  final String id;
  final String name;
  final String zoneId;
  final bool isActive;
  final int intervalMinutes;

  Sensor({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.isActive,
    required this.intervalMinutes,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'] as String,
      name: json['name'] as String,
      zoneId: json['zone_id'] as String,
      isActive: json['is_active'] as bool,
      intervalMinutes: json['interval_minutes'] as int? ?? 15,
    );
  }
}

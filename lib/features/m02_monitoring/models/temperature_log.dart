class TemperatureLog {
  final String id;
  final String sensorId;
  final double temperature;
  final DateTime recordedAt;
  final bool isAlert;

  TemperatureLog({
    required this.id,
    required this.sensorId,
    required this.temperature,
    required this.recordedAt,
    required this.isAlert,
  });

  factory TemperatureLog.fromJson(Map<String, dynamic> json) {
    return TemperatureLog(
      id: json['id'] as String,
      sensorId: json['sensor_id'] as String,
      temperature: (json['temperature_celsius'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      isAlert: json['is_alert'] as bool? ?? false,
    );
  }
}

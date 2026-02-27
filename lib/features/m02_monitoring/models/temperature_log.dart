class TemperatureLog {
  final String id;
  final String sensorId;
  final double temperature;
  final DateTime recordedAt;
  final bool isAlert;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? editedBy;
  final DateTime? editedAt;
  final String? editReason;

  TemperatureLog({
    required this.id,
    required this.sensorId,
    required this.temperature,
    required this.recordedAt,
    required this.isAlert,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.editedBy,
    this.editedAt,
    this.editReason,
  });

  factory TemperatureLog.fromJson(Map<String, dynamic> json) {
    return TemperatureLog(
      id: json['id'] as String,
      sensorId: json['sensor_id'] as String,
      temperature: (json['temperature_celsius'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      isAlert: json['is_alert'] as bool? ?? false,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedBy: json['acknowledged_by'] as String?,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      editedBy: json['edited_by'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      editReason: json['edit_reason'] as String?,
    );
  }
}

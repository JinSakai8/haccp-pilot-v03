class AlarmListItem {
  final String logId;
  final String sensorId;
  final String sensorName;
  final double temperature;
  final DateTime startedAt;
  final DateTime lastSeenAt;
  final int durationMinutes;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  const AlarmListItem({
    required this.logId,
    required this.sensorId,
    required this.sensorName,
    required this.temperature,
    required this.startedAt,
    required this.lastSeenAt,
    required this.durationMinutes,
    required this.isAcknowledged,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  factory AlarmListItem.fromJson(Map<String, dynamic> json) {
    return AlarmListItem(
      logId: json['log_id'] as String,
      sensorId: json['sensor_id'] as String,
      sensorName: (json['sensor_name'] as String?)?.trim().isNotEmpty == true
          ? json['sensor_name'] as String
          : 'Sensor',
      temperature: (json['temperature'] as num).toDouble(),
      startedAt: DateTime.parse(json['started_at'] as String),
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
    );
  }
}

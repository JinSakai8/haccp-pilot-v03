class DailyTemperatureStats {
  final DateTime date;
  final String deviceName;
  final double minTemp;
  final double maxTemp;
  final double avgTemp;
  final int measurementCount;
  final bool hasCriticalBreach;

  DailyTemperatureStats({
    required this.date,
    required this.deviceName,
    required this.minTemp,
    required this.maxTemp,
    required this.avgTemp,
    required this.measurementCount,
    required this.hasCriticalBreach,
  });

  @override
  String toString() {
    return 'DailyTemperatureStats(date: ${date.toIso8601String().substring(0, 10)}, device: $deviceName, min: $minTemp, max: $maxTemp, avg: ${avgTemp.toStringAsFixed(1)}, count: $measurementCount, alert: $hasCriticalBreach)';
  }
}

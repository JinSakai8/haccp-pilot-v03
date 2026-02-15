import 'package:haccp_pilot/features/m06_reports/models/daily_temperature_stats.dart';

class HtmlReportGenerator {
  /// Generates a complete HTML document string for a monthly temperature report.
  static String generateHtml({
    required List<DailyTemperatureStats> stats,
    required DateTime month,
    String? userName,
    String? venueName,
  }) {
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    
    // Create rows
    final rowsBuffer = StringBuffer();
    for (var stat in stats) {
      final dateStr = stat.date.toIso8601String().substring(0, 10);
      final statusClass = stat.hasCriticalBreach ? 'status-error' : 'status-ok';
      final statusText = stat.hasCriticalBreach ? 'ALARM' : 'OK';
      
      rowsBuffer.writeln('''
        <tr>
          <td>$dateStr</td>
          <td>${stat.deviceName}</td>
          <td>${stat.minTemp.toStringAsFixed(1)} °C</td>
          <td>${stat.maxTemp.toStringAsFixed(1)} °C</td>
          <td>${stat.avgTemp.toStringAsFixed(1)} °C</td>
          <td class="$statusClass">$statusText</td>
        </tr>
      ''');
    }

    return '''
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <title>Raport Temperatur $monthStr</title>
    <style>
        body { font-family: sans-serif; margin: 20px; color: #000; background: #fff; }
        h1 { text-align: center; margin-bottom: 5px; }
        .meta { text-align: center; margin-bottom: 20px; color: #555; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #000; padding: 8px; text-align: center; }
        th { background-color: #f0f0f0; }
        .status-ok { color: green; font-weight: bold; }
        .status-error { color: red; font-weight: bold; background-color: #ffe6e6; }
        @media print {
            body { margin: 0; }
            th { background-color: #ccc !important; -webkit-print-color-adjust: exact; }
            .status-error { background-color: #ffe6e6 !important; -webkit-print-color-adjust: exact; }
        }
    </style>
</head>
<body>
    <h1>Karta Kontroli Temperatur</h1>
    <div class="meta">
        Miesiąc: <strong>$monthStr</strong> <br>
        Lokal: ${venueName ?? 'Domyślny'} <br>
        Wygenerował: ${userName ?? 'System'}
    </div>

    <table>
        <thead>
            <tr>
                <th>Data</th>
                <th>Urządzenie</th>
                <th>Min</th>
                <th>Max</th>
                <th>Średnia</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            ${rowsBuffer.toString()}
        </tbody>
    </table>
    
    <div style="margin-top: 30px; font-size: 12px; text-align: right;">
        Wygenerowano z systemu HACCP Pilot v3
    </div>
</body>
</html>
    ''';
  }
}

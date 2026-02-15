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
    
    // Calculate Summary Stats
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    int totalBreaches = 0;
    int totalMeasurements = 0;

    for (var stat in stats) {
      if (stat.minTemp < globalMin) globalMin = stat.minTemp;
      if (stat.maxTemp > globalMax) globalMax = stat.maxTemp;
      if (stat.hasCriticalBreach) totalBreaches++;
      totalMeasurements += stat.measurementCount;
    }

    if (globalMin == double.infinity) globalMin = 0;
    if (globalMax == double.negativeInfinity) globalMax = 0;

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
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; color: #333; background: #fff; }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #D2661E;
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        
        .header-logo {
            font-size: 24px;
            font-weight: bold;
            color: #D2661E;
            text-transform: uppercase;
        }

        .header-info {
            text-align: right;
            font-size: 14px;
            color: #666;
        }

        h1 { 
            text-align: center; 
            color: #2c3e50;
            font-size: 28px;
            margin-bottom: 5px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .report-meta {
            text-align: center;
            margin-bottom: 30px;
            font-size: 16px;
            color: #555;
        }

        .summary-box {
            display: flex;
            justify-content: space-around;
            background-color: #f8f9fa;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 30px;
        }

        .summary-item {
            text-align: center;
        }

        .summary-value {
            font-size: 20px;
            font-weight: bold;
            color: #D2661E;
        }

        .summary-label {
            font-size: 12px;
            color: #777;
            text-transform: uppercase;
        }

        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin-top: 10px; 
            font-size: 14px; 
        }

        th, td { 
            border: 1px solid #ddd; 
            padding: 10px; 
            text-align: center; 
        }

        th { 
            background-color: #2c3e50; 
            color: white; 
            font-weight: 600; 
        }

        tr:nth-child(even) { background-color: #f9f9f9; }

        .status-ok { 
            color: #27ae60; 
            font-weight: bold; 
        }

        .status-error { 
            color: #c0392b; 
            font-weight: bold; 
            background-color: #fadbd8; 
        }

        .footer {
            margin-top: 40px;
            border-top: 1px solid #ddd;
            padding-top: 10px;
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            color: #999;
        }

        @media print {
            body { margin: 0; padding: 0; }
            .header-info, .summary-box { -webkit-print-color-adjust: exact; }
            th { background-color: #2c3e50 !important; color: white !important; -webkit-print-color-adjust: exact; }
            tr:nth-child(even) { background-color: #f0f0f0 !important; -webkit-print-color-adjust: exact; }
            .status-error { background-color: #fadbd8 !important; -webkit-print-color-adjust: exact; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-logo">HACCP Pilot</div>
        <div class="header-info">
            Lokal: <strong>${venueName ?? 'Brak danych'}</strong><br>
            Raport miesięczny
        </div>
    </div>

    <h1>Karta Kontroli Temperatur</h1>
    <div class="report-meta">
        Miesiąc: <strong>$monthStr</strong> &nbsp;|&nbsp; Wygenerował: ${userName ?? 'System'}
    </div>

    <div class="summary-box">
        <div class="summary-item">
            <div class="summary-value">${stats.length}</div>
            <div class="summary-label">Dni pomiarowe</div>
        </div>
        <div class="summary-item">
            <div class="summary-value">$totalMeasurements</div>
            <div class="summary-label">Liczba odczytów</div>
        </div>
        <div class="summary-item">
            <div class="summary-value">${globalMin.toStringAsFixed(1)}°C / ${globalMax.toStringAsFixed(1)}°C</div>
            <div class="summary-label">Min / Max miesiąca</div>
        </div>
        <div class="summary-item">
            <div class="summary-value" style="color: ${totalBreaches > 0 ? '#c0392b' : '#27ae60'}">$totalBreaches</div>
            <div class="summary-label">Alarmy</div>
        </div>
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
    
    <div class="footer">
        <div>Wygenerowano automatycznie z systemu HACCP Pilot v3</div>
        <div>Data wydruku: ${DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' ')}</div>
    </div>
</body>
</html>
    ''';
  }
}

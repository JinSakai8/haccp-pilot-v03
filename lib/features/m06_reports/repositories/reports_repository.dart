import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haccp_pilot/core/services/supabase_service.dart';
// import 'package:http/http.dart' as http; // Use supabase storage download instead

const bool _reportsDebugLogs = bool.fromEnvironment(
  'HACCP_REPORTS_DEBUG',
  defaultValue: false,
);

void _reportsLog(String message) {
  if (_reportsDebugLogs) {
    debugPrint('[ReportsRepository] $message');
  }
}

class Ccp1TemperatureQuerySpec {
  final DateTime start;
  final DateTime end;
  final String sensorId;

  const Ccp1TemperatureQuerySpec({
    required this.start,
    required this.end,
    required this.sensorId,
  });
}

@visibleForTesting
Ccp1TemperatureQuerySpec buildCcp1TemperatureQuerySpec(
  DateTime month,
  String sensorId,
) {
  final normalizedSensorId = sensorId.trim();
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(
    month.year,
    month.month + 1,
    1,
  ).subtract(const Duration(milliseconds: 1));

  return Ccp1TemperatureQuerySpec(
    start: start,
    end: end,
    sensorId: normalizedSensorId,
  );
}

class Ccp1TemperatureReportRow {
  final String date;
  final String time;
  final String temperature;
  final String compliance;
  final String correctiveActions;
  final String signature;

  const Ccp1TemperatureReportRow({
    required this.date,
    required this.time,
    required this.temperature,
    required this.compliance,
    required this.correctiveActions,
    required this.signature,
  });

  List<String> toPdfColumns() {
    return <String>[
      date,
      time,
      temperature,
      compliance,
      correctiveActions,
      signature,
    ];
  }
}

class Ccp1TemperatureDataset {
  final String sensorId;
  final String sensorName;
  final DateTime month;
  final List<Ccp1TemperatureReportRow> rows;

  const Ccp1TemperatureDataset({
    required this.sensorId,
    required this.sensorName,
    required this.month,
    required this.rows,
  });
}

@visibleForTesting
Ccp1TemperatureReportRow mapTemperatureLogToCcp1Row(Map<String, dynamic> raw) {
  final recordedAt = DateTime.parse(raw['recorded_at'] as String);
  final temperatureValue = (raw['temperature_celsius'] as num).toDouble();
  final isCompliant = temperatureValue >= 0.0 && temperatureValue <= 4.0;

  final day = recordedAt.day.toString().padLeft(2, '0');
  final month = recordedAt.month.toString().padLeft(2, '0');
  final year = recordedAt.year.toString();
  final hour = recordedAt.hour.toString().padLeft(2, '0');
  final minute = recordedAt.minute.toString().padLeft(2, '0');

  return Ccp1TemperatureReportRow(
    date: '$day.$month.$year',
    time: '$hour:$minute',
    temperature: '${temperatureValue.toStringAsFixed(1)}\u00B0C',
    compliance: isCompliant ? 'TAK' : 'NIE',
    correctiveActions: '',
    signature: '',
  );
}

class CoolingLogsQuerySpec {
  final DateTime start;
  final DateTime end;
  final String category;
  final String formId;
  final String? zoneId;
  final String? venueId;

  const CoolingLogsQuerySpec({
    required this.start,
    required this.end,
    required this.category,
    required this.formId,
    this.zoneId,
    this.venueId,
  });

  bool get usesZoneFilter => zoneId != null && zoneId!.isNotEmpty;
  bool get usesVenueFallback =>
      !usesZoneFilter && venueId != null && venueId!.isNotEmpty;
}

@visibleForTesting
CoolingLogsQuerySpec buildCoolingLogsQuerySpec(
  DateTime month, {
  String? zoneId,
  String? venueId,
}) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(
    month.year,
    month.month + 1,
    1,
  ).subtract(const Duration(milliseconds: 1));

  final normalizedZoneId = (zoneId != null && zoneId.trim().isNotEmpty)
      ? zoneId.trim()
      : null;
  final normalizedVenueId = (venueId != null && venueId.trim().isNotEmpty)
      ? venueId.trim()
      : null;

  return CoolingLogsQuerySpec(
    start: start,
    end: end,
    category: 'gmp',
    formId: 'food_cooling',
    zoneId: normalizedZoneId,
    venueId: normalizedVenueId,
  );
}

class RoastingLogsQuerySpec {
  final DateTime start;
  final DateTime end;
  final String category;
  final List<String> formIds;
  final String? zoneId;
  final String? venueId;

  const RoastingLogsQuerySpec({
    required this.start,
    required this.end,
    required this.category,
    required this.formIds,
    this.zoneId,
    this.venueId,
  });

  bool get usesZoneFilter => zoneId != null && zoneId!.isNotEmpty;
  bool get usesVenueFallback =>
      !usesZoneFilter && venueId != null && venueId!.isNotEmpty;
}

@visibleForTesting
DateTime? resolveRoastingLogBusinessDate(Map<String, dynamic> raw) {
  final data = (raw['data'] as Map?)?.cast<String, dynamic>();
  final prepDateRaw = data?['prep_date']?.toString();
  if (prepDateRaw != null && prepDateRaw.isNotEmpty) {
    final parsedPrepDate = DateTime.tryParse(prepDateRaw);
    if (parsedPrepDate != null) {
      return DateTime(
        parsedPrepDate.year,
        parsedPrepDate.month,
        parsedPrepDate.day,
      );
    }
  }

  final createdAtRaw = raw['created_at']?.toString();
  if (createdAtRaw == null || createdAtRaw.isEmpty) return null;
  return DateTime.tryParse(createdAtRaw);
}

@visibleForTesting
bool isRoastingLogInMonth(Map<String, dynamic> raw, DateTime month) {
  final businessDate = resolveRoastingLogBusinessDate(raw);
  if (businessDate == null) return false;
  return businessDate.year == month.year && businessDate.month == month.month;
}

@visibleForTesting
RoastingLogsQuerySpec buildRoastingLogsQuerySpec(
  DateTime month, {
  String? zoneId,
  String? venueId,
}) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(
    month.year,
    month.month + 1,
    1,
  ).subtract(const Duration(milliseconds: 1));

  final normalizedZoneId = (zoneId != null && zoneId.trim().isNotEmpty)
      ? zoneId.trim()
      : null;
  final normalizedVenueId = (venueId != null && venueId.trim().isNotEmpty)
      ? venueId.trim()
      : null;

  return RoastingLogsQuerySpec(
    start: start,
    end: end,
    category: 'gmp',
    formIds: const <String>['meat_roasting', 'meat_roasting_daily'],
    zoneId: normalizedZoneId,
    venueId: normalizedVenueId,
  );
}

class ReportsRepository {
  Future<List<Map<String, dynamic>>> getWasteRecords(
    DateTime start,
    DateTime end,
  ) async {
    final response = await SupabaseService.client
        .from('waste_records')
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCoolingLogs(
    DateTime date, {
    String? zoneId,
    String? venueId,
  }) async {
    final spec = buildCoolingLogsQuerySpec(
      date,
      zoneId: zoneId,
      venueId: venueId,
    );

    var query = SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', spec.category)
        .eq('form_id', spec.formId)
        .gte('created_at', spec.start.toIso8601String())
        .lte('created_at', spec.end.toIso8601String());

    if (spec.usesZoneFilter) {
      query = query.eq('zone_id', spec.zoneId!);
    } else if (spec.usesVenueFallback) {
      query = query.eq('venue_id', spec.venueId!);
    }

    final response = await query.order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRoastingLogs(
    DateTime month, {
    String? zoneId,
    String? venueId,
  }) async {
    final spec = buildRoastingLogsQuerySpec(
      month,
      zoneId: zoneId,
      venueId: venueId,
    );

    final prepDateStart = spec.start.toIso8601String().split('T')[0];
    final prepDateEnd = spec.end.toIso8601String().split('T')[0];
    _reportsLog(
      'getRoastingLogs spec: month=${month.toIso8601String()} '
      'range=${spec.start.toIso8601String()}..${spec.end.toIso8601String()} '
      'zoneId=${spec.zoneId} venueId=${spec.venueId} formIds=${spec.formIds}',
    );

    var prepDateQuery = SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', spec.category)
        .inFilter('form_id', spec.formIds)
        .gte('data->>prep_date', prepDateStart)
        .lte('data->>prep_date', prepDateEnd);

    var legacyQuery = SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', spec.category)
        .inFilter('form_id', spec.formIds)
        .isFilter('data->>prep_date', null)
        .gte('created_at', spec.start.toIso8601String())
        .lte('created_at', spec.end.toIso8601String());

    if (spec.usesZoneFilter) {
      prepDateQuery = prepDateQuery.eq('zone_id', spec.zoneId!);
      legacyQuery = legacyQuery.eq('zone_id', spec.zoneId!);
    } else if (spec.usesVenueFallback) {
      prepDateQuery = prepDateQuery.eq('venue_id', spec.venueId!);
      legacyQuery = legacyQuery.eq('venue_id', spec.venueId!);
    }

    final prepDateResponse = await prepDateQuery.order('created_at');
    final legacyResponse = await legacyQuery.order('created_at');
    _reportsLog(
      'getRoastingLogs raw counts: prep_date=${prepDateResponse.length} '
      'legacy=${legacyResponse.length}',
    );

    final mergedById = <String, Map<String, dynamic>>{};
    for (final row in [
      ...List<Map<String, dynamic>>.from(prepDateResponse),
      ...List<Map<String, dynamic>>.from(legacyResponse),
    ]) {
      final key =
          row['id']?.toString() ??
          '${row['created_at']}_${row['form_id']}_${row['user_id']}';
      mergedById[key] = row;
    }

    final merged =
        mergedById.values
            .where((row) => isRoastingLogInMonth(row, month))
            .toList()
          ..sort((a, b) {
            final left = resolveRoastingLogBusinessDate(a);
            final right = resolveRoastingLogBusinessDate(b);
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return left.compareTo(right);
          });
    _reportsLog('getRoastingLogs final count=${merged.length}');

    return merged;
  }

  Future<Map<String, dynamic>?> getVenueProfile(String venueId) async {
    try {
      final response = await SupabaseService.client
          .from('venues')
          .select('name, address, logo_url')
          .eq('id', venueId)
          .maybeSingle();
      return response;
    } catch (e) {
      _reportsLog('getVenueProfile failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getGmpLogs(
    DateTime start,
    DateTime end,
  ) async {
    // CORRECTED: Read from unified 'haccp_logs' table with category filter
    final response = await SupabaseService.client
        .from('haccp_logs')
        .select()
        .eq('category', 'gmp')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMeasurements(
    DateTime start,
    DateTime end,
  ) async {
    // We join 'sensors' table to get the name.
    // The query '*, sensors(name)' fetches all measurement columns + sensor name.
    final response = await SupabaseService.client
        .from('temperature_logs')
        .select('*, sensors(name)')
        .gte(
          'recorded_at',
          start.toIso8601String(),
        ) // Note: field is recorded_at, not timestamp
        .lte('recorded_at', end.toIso8601String())
        .order('recorded_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMonthlySensorMeasurements(
    DateTime month,
    String sensorId,
  ) async {
    final spec = buildCcp1TemperatureQuerySpec(month, sensorId);
    final response = await SupabaseService.client
        .from('temperature_logs')
        .select('sensor_id, temperature_celsius, recorded_at, sensors(name)')
        .eq('sensor_id', spec.sensorId)
        .gte('recorded_at', spec.start.toIso8601String())
        .lte('recorded_at', spec.end.toIso8601String())
        .order('recorded_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Ccp1TemperatureDataset> getCcp1TemperatureDataset({
    required DateTime month,
    required String sensorId,
  }) async {
    final normalizedSensorId = sensorId.trim();
    final records = await getMonthlySensorMeasurements(
      month,
      normalizedSensorId,
    );

    final sensorName = records.isNotEmpty && records.first['sensors'] is Map
        ? (records.first['sensors']['name']?.toString() ??
              'Sensor $normalizedSensorId')
        : 'Sensor $normalizedSensorId';

    final rows = records.map(mapTemperatureLogToCcp1Row).toList();

    return Ccp1TemperatureDataset(
      sensorId: normalizedSensorId,
      sensorName: sensorName,
      month: DateTime(month.year, month.month, 1),
      rows: rows,
    );
  }

  /// Helper to fetch logo bytes if available for a venue
  Future<Uint8List?> getVenueLogo(String venueId) async {
    try {
      final venue = await SupabaseService.client
          .from('venues')
          .select('logo_url')
          .eq('id', venueId)
          .maybeSingle();

      if (venue == null || venue['logo_url'] == null) return null;

      final logoUrl = venue['logo_url'] as String;
      // Extract path from public URL or store path directly?
      // If logo_url is full public URL: https://.../storage/v1/object/public/branding/logos/...
      // Supabase download needs the path relative to bucket.
      // Current upload implementation stores full URL in DB.
      // So we must download via HTTP or parse path.
      // Supabase helper download() works on bucket paths.
      // Easier: Use http.get since it is a public URL.

      // Since we don't have http package imported in this file, let's use Supabase storage
      // if we can extract the path.
      // URL format: .../branding/logos/venueId/timestamp.jpg

      final uri = Uri.parse(logoUrl);
      final segments = uri.pathSegments;
      // segments usually: ['storage', 'v1', 'object', 'public', 'branding', 'logos', ...]
      // We want 'logos/...'

      final brandingIndex = segments.indexOf('branding');
      if (brandingIndex != -1 && brandingIndex + 1 < segments.length) {
        final path = segments.sublist(brandingIndex + 1).join('/');
        // path = 'logos/venueId/...'
        final bytes = await SupabaseService.client.storage
            .from('branding')
            .download(path);
        return bytes;
      }
    } catch (e) {
      debugPrint('Error fetching logo: $e');
    }
    return null;
  }

  /// Uploads report bytes to Supabase Storage
  Future<String?> uploadReport(String path, Uint8List bytes) async {
    try {
      await SupabaseService.client.storage
          .from('reports')
          .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true));
      return path;
    } catch (e) {
      debugPrint('Error uploading report: $e');
      return null;
    }
  }

  /// Saves report metadata to the database
  Future<void> saveReportMetadata({
    required String venueId,
    required String reportType,
    required DateTime generationDate,
    required String storagePath,
    required String userId,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? templateVersion,
    String? sourceFormId,
    Map<String, dynamic>? metadata,
  }) async {
    final resolvedPeriodStart =
        periodStart ??
        DateTime(generationDate.year, generationDate.month, generationDate.day);
    final resolvedPeriodEnd =
        periodEnd ??
        DateTime(
          generationDate.year,
          generationDate.month,
          generationDate.day + 1,
        ).subtract(const Duration(milliseconds: 1));

    final resolvedTemplateVersion =
        templateVersion ??
        switch (reportType) {
          'ccp2_roasting' => 'ccp2_pdf_v2',
          'ccp3_cooling' => 'ccp3_pdf_v2',
          'ccp1_temperature' => 'ccp1_csv_v1',
          _ => 'pdf_v1',
        };

    final resolvedSourceFormId =
        sourceFormId ??
        switch (reportType) {
          'ccp2_roasting' => 'meat_roasting',
          'ccp3_cooling' => 'food_cooling',
          'ccp1_temperature' => 'temperature_logs',
          _ => 'unknown',
        };

    final mergedMetadata = <String, dynamic>{
      'period_start': resolvedPeriodStart.toIso8601String().split('T')[0],
      'period_end': resolvedPeriodEnd.toIso8601String().split('T')[0],
      'template_version': resolvedTemplateVersion,
      'source_form_id': resolvedSourceFormId,
      ...?metadata,
    };

    await SupabaseService.client.from('generated_reports').upsert({
      'venue_id': venueId,
      'report_type': reportType,
      'generation_date': generationDate.toIso8601String().split('T')[0],
      'created_by': userId,
      'storage_path': storagePath,
      'metadata': mergedMetadata,
    }, onConflict: 'venue_id,report_type,generation_date');
  }

  /// Checks if a report already exists for the given date and type
  Future<Map<String, dynamic>?> getSavedReport(
    DateTime date,
    String type, {
    required String venueId,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    _reportsLog(
      'getSavedReport lookup: venue=$venueId type=$type date=$dateStr',
    );
    try {
      final response = await SupabaseService.client
          .from('generated_reports')
          .select()
          .eq('venue_id', venueId)
          .eq('generation_date', dateStr)
          .eq('report_type', type)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      _reportsLog(
        'getSavedReport result: ${response == null ? 'miss' : 'hit'}',
      );
      return response;
    } catch (e) {
      _reportsLog('getSavedReport failed: $e');
      return null;
    }
  }

  /// Downloads a report from storage
  Future<Uint8List?> downloadReport(String path) async {
    try {
      final normalizedPath = path.startsWith('reports/')
          ? path.substring('reports/'.length)
          : path;
      _reportsLog('downloadReport path=$normalizedPath');
      final bytes = await SupabaseService.client.storage
          .from('reports')
          .download(normalizedPath);
      _reportsLog('downloadReport bytes=${bytes.length}');
      return bytes;
    } catch (e) {
      debugPrint('Error downloading report: $e');
      return null;
    }
  }

  /// Fetches list of generated reports for a venue
  Future<List<Map<String, dynamic>>> getGeneratedReports(String venueId) async {
    try {
      final response = await SupabaseService.client
          .from('generated_reports')
          .select()
          .eq('venue_id', venueId)
          .order('generation_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching generated reports: $e');
      return [];
    }
  }
}

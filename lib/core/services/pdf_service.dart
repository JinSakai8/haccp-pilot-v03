import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:haccp_pilot/features/shared/models/form_definition.dart';
import 'package:haccp_pilot/core/services/file_opener.dart'; // Conditional import helper

/// Service for generating PDF reports.
/// Uses [compute] to run heavy PDF generation in a separate isolate.
class PdfService {
  final bool useIsolate;

  PdfService({this.useIsolate = true});

  /// Generates a PDF report for a generic form (GMP/GHP).
  Future<Uint8List> generateFormReport({
    required String title,
    required FormDefinition definition,
    required Map<String, dynamic> data,
    required String userName,
    required String date,
    Uint8List? logoBytes,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    
    final images = <String, Uint8List>{};
    
    if (logoBytes != null) {
      images['__venue_logo__'] = logoBytes;
    }
    
    for (var field in definition.fields) {
      if (field.type == HaccpFieldType.photo) {
        final path = data[field.id];
        if (path != null && path is String && path.isNotEmpty) {
            try {
              // On web, we can only download from Supabase (no local files)
              try {
                final Uint8List bytes = await Supabase.instance.client.storage
                    .from('waste-docs')
                    .download(path);
                
                if (bytes.isNotEmpty) {
                  images[field.id] = bytes;
                }
              } catch (storageError) {
                debugPrint('Supabase Storage Download Error for $path: $storageError');
              }
            } catch (e) {
              debugPrint('Error loading image for PDF: $e');
            }
        }
      }
    }

    final params = _PdfGenerationParams(
      title: title,
      definition: definition,
      data: data,
      userName: userName,
      date: date,
      images: images,
      fontBytes: fontData.buffer.asUint8List(),
      boldFontBytes: boldFontData.buffer.asUint8List(),
    );

    // compute doesn't work on web, so run directly
    if (kIsWeb || !useIsolate) {
      return await _generatePdfIsolate(params);
    }
    return await compute(_generatePdfIsolate, params);
  }

  /// The static method that runs in an isolate.
  static Future<Uint8List> _generatePdfIsolate(_PdfGenerationParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    
    final font = _createRegularFont(params.fontBytes, 12);
    final boldFont = _createBoldFont(params.boldFontBytes, 14);

    graphics.drawString(
      params.title.toUpperCase(),
      boldFont,
      bounds: Rect.fromLTWH(0, 0, 500, 30),
    );

    if (params.images.containsKey('__venue_logo__')) {
      final logoBytes = params.images['__venue_logo__']!;
      final logoBitmap = PdfBitmap(logoBytes);
      const logoWidth = 60.0;
      final logoHeight = logoBitmap.height * (logoWidth / logoBitmap.width);
      graphics.drawImage(logoBitmap, Rect.fromLTWH(420, 0, logoWidth, logoHeight));
    }

    graphics.drawString(
      'Data: ${params.date} | Wykonał: ${params.userName}',
      font,
      bounds: Rect.fromLTWH(0, 30, 500, 20),
    );

    final grid = PdfGrid();
    grid.columns.add(count: 2);
    grid.headers.add(1);
    final header = grid.headers[0];
    header.cells[0].value = 'Parametr';
    header.cells[1].value = 'Wartość / Uwagi';

    for (var field in params.definition.fields) {
      final row = grid.rows.add();
      row.cells[0].value = field.label;

      final val = params.data[field.id];
      
      if (field.type == HaccpFieldType.photo) {
        final imageBytes = params.images[field.id];
        if (imageBytes != null) {
           row.cells[1].value = '[ZDJĘCIE ZAŁĄCZONE NIŻEJ]';
        } else {
           row.cells[1].value = '[ZDJĘCIE NIEDOSTĘPNE]';
        }
      } else if (field.type == HaccpFieldType.toggle) {
         final boolValue = val == true;
         row.cells[1].value = boolValue ? 'ZGODNE' : 'NIEZGODNE';
         final commentKey = '${field.id}_comment';
         if (params.data.containsKey(commentKey)) {
           row.cells[1].value = '${row.cells[1].value}\nUwagi: ${params.data[commentKey]}';
         }
      } else {
         row.cells[1].value = val?.toString() ?? '-';
      }
    }

    final layoutResult = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 60, 0, 0),
    );

    var currentY = layoutResult!.bounds.bottom + 20;
    
    if (params.images.isNotEmpty) {
      graphics.drawString('ZAŁĄCZNIKI ZDJĘCIOWE:', boldFont, bounds: Rect.fromLTWH(0, currentY, 500, 20));
      currentY += 30;

      for (var entry in params.images.entries) {
        if (entry.key == '__venue_logo__') continue;

        final imageBytes = entry.value;
        final pdfBitmap = PdfBitmap(imageBytes);
        
        const maxWidth = 400.0;
        final scale = maxWidth / pdfBitmap.width;
        final height = pdfBitmap.height * scale;

        if (currentY + height > page.getClientSize().height) {
           final newPage = document.pages.add();
           newPage.graphics.drawImage(pdfBitmap, Rect.fromLTWH(0, 20, maxWidth, height));
        } else {
           graphics.drawImage(pdfBitmap, Rect.fromLTWH(0, currentY, maxWidth, height));
           currentY += height + 20;
        }
      }
    }

    final List<int> bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Generates a tabular report (e.g. Monthly Waste Log, Temperature Log).
  Future<Uint8List> generateTableReport({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    required String userName,
    required String dateRange,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    final params = _PdfTableParams(
      title: title,
      columns: columns,
      rows: rows,
      userName: userName,
      dateRange: dateRange,
      fontBytes: fontData.buffer.asUint8List(),
      boldFontBytes: boldFontData.buffer.asUint8List(),
    );

    if (kIsWeb || !useIsolate) {
      return await _generateTablePdfIsolate(params);
    }
    return await compute(_generateTablePdfIsolate, params);
  }

  static Future<Uint8List> _generateTablePdfIsolate(_PdfTableParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final font = _createRegularFont(params.fontBytes, 10);
    final boldFont = _createBoldFont(params.boldFontBytes, 14);

    graphics.drawString(
      params.title.toUpperCase(),
      boldFont,
      bounds: Rect.fromLTWH(0, 0, 500, 30),
    );

    graphics.drawString(
      'Okres: ${params.dateRange} | Generował: ${params.userName}',
      font,
      bounds: Rect.fromLTWH(0, 30, 500, 20),
    );

    final grid = PdfGrid();
    grid.columns.add(count: params.columns.length);
    final header = grid.headers.add(1)[0];
    
    for (int i = 0; i < params.columns.length; i++) {
      header.cells[i].value = params.columns[i];
    }

    for (var rowData in params.rows) {
      final row = grid.rows.add();
      for (int i = 0; i < rowData.length; i++) {
        if (i < row.cells.count) {
          row.cells[i].value = rowData[i];
        }
      }
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 60, 0, 0),
    );

    final List<int> bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Generates CCP-1 monthly temperature report with a fixed layout.
  Future<Uint8List> generateCcp1TemperatureReport({
    required String sensorName,
    required String userName,
    required String monthLabel,
    required List<List<String>> rows,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    final params = _Ccp1TemperatureReportParams(
      sensorName: sensorName,
      userName: userName,
      monthLabel: monthLabel,
      rows: rows,
      fontBytes: fontData.buffer.asUint8List(),
      boldFontBytes: boldFontData.buffer.asUint8List(),
    );

    if (kIsWeb || !useIsolate) {
      return await _generateCcp1TemperaturePdfIsolate(params);
    }
    return await compute(_generateCcp1TemperaturePdfIsolate, params);
  }

  static Future<Uint8List> _generateCcp1TemperaturePdfIsolate(
    _Ccp1TemperatureReportParams params,
  ) async {
    final document = PdfDocument();
    document.pageSettings.margins.all = 20;

    // Footer template on every page.
    final footer = PdfPageTemplateElement(const Rect.fromLTWH(0, 0, 520, 24));
    final footerFont = _createRegularFont(params.fontBytes, 9);
    final footerBold = _createBoldFont(params.boldFontBytes, 9);
    footer.graphics.drawString(
      'Sprawdzil/zatwierdzil: .................................................',
      footerBold,
      bounds: const Rect.fromLTWH(0, 0, 400, 14),
    );
    footer.graphics.drawString(
      '(Data/podpis)',
      footerFont,
      bounds: const Rect.fromLTWH(180, 12, 120, 12),
    );
    document.template.bottom = footer;

    final page = document.pages.add();
    final graphics = page.graphics;
    final font = _createRegularFont(params.fontBytes, 9);
    final boldFont = _createBoldFont(params.boldFontBytes, 10);
    final titleFont = _createBoldFont(params.boldFontBytes, 14);
    final pageWidth = page.getClientSize().width;

    // Header row.
    final topGrid = PdfGrid();
    topGrid.columns.add(count: 3);
    topGrid.columns[0].width = pageWidth * 0.35;
    topGrid.columns[1].width = pageWidth * 0.35;
    topGrid.columns[2].width = pageWidth * 0.30;

    final topRow = topGrid.rows.add();
    topRow.cells[0].value =
        'Restauracja "Mieso i Piana"\nul. Energetykow 18A,\n37-450 Stalowa Wola';
    topRow.cells[0].style.font = boldFont;
    topRow.cells[0].stringFormat = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    topRow.cells[1].value = 'Arkusz monitorowania CCP-1';
    topRow.cells[1].style.font = titleFont;
    topRow.cells[1].stringFormat = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    topRow.cells[2].value = 'Odpowiedzialny:\nUpowazniony pracownik';
    topRow.cells[2].style.font = font;
    topRow.cells[2].stringFormat = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.middle,
    );
    topRow.height = 56;

    final topLayout = topGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 0, pageWidth, 0),
    );
    double currentY = topLayout!.bounds.bottom + 6;

    // Parameters section.
    final paramsGrid = PdfGrid();
    paramsGrid.columns.add(count: 2);
    paramsGrid.columns[0].width = pageWidth * 0.5;
    paramsGrid.columns[1].width = pageWidth * 0.5;

    final paramsHeader = paramsGrid.headers.add(1)[0];
    paramsHeader.cells[0].value = 'Parametr';
    paramsHeader.cells[1].value = 'Wartosc';
    for (var i = 0; i < 2; i++) {
      paramsHeader.cells[i].style.font = boldFont;
      paramsHeader.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(229, 229, 229));
    }

    final sensorRow = paramsGrid.rows.add();
    sensorRow.cells[0].value = 'Urzadzenie / sensor';
    sensorRow.cells[1].value = params.sensorName;

    final monthRow = paramsGrid.rows.add();
    monthRow.cells[0].value = 'Okres';
    monthRow.cells[1].value = params.monthLabel;

    final limitsRow = paramsGrid.rows.add();
    limitsRow.cells[0].value = 'Kryterium zgodnosci';
    limitsRow.cells[1].value = 'TAK dla 0.0..4.0 C, NIE poza zakresem';

    for (var rowIndex = 0; rowIndex < paramsGrid.rows.count; rowIndex++) {
      final row = paramsGrid.rows[rowIndex];
      for (var i = 0; i < row.cells.count; i++) {
        row.cells[i].style.font = font;
      }
    }

    final paramsLayout = paramsGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, currentY, pageWidth, 0),
    );
    currentY = paramsLayout!.bounds.bottom + 8;

    // Main CCP-1 table.
    final dataGrid = PdfGrid();
    dataGrid.repeatHeader = true;
    dataGrid.columns.add(count: 6);
    dataGrid.columns[0].width = pageWidth * 0.14;
    dataGrid.columns[1].width = pageWidth * 0.12;
    dataGrid.columns[2].width = pageWidth * 0.16;
    dataGrid.columns[3].width = pageWidth * 0.17;
    dataGrid.columns[4].width = pageWidth * 0.27;
    dataGrid.columns[5].width = pageWidth * 0.14;

    final header = dataGrid.headers.add(1)[0];
    final headers = <String>[
      'Data',
      'Godzina',
      'Wartosc temperatury',
      'Zgodnosc z ustaleniami',
      'Dzialania korygujace',
      'Podpis',
    ];
    for (var i = 0; i < headers.length; i++) {
      header.cells[i].value = headers[i];
      header.cells[i].style.font = boldFont;
      header.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(229, 229, 229));
      header.cells[i].stringFormat = PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      );
    }
    header.height = 26;

    for (final rowValues in params.rows) {
      final row = dataGrid.rows.add();
      for (var i = 0; i < headers.length; i++) {
        row.cells[i].value = i < rowValues.length ? rowValues[i] : '';
        row.cells[i].style.font = font;
        row.cells[i].stringFormat = PdfStringFormat(
          alignment: i == 4 ? PdfTextAlignment.left : PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        );
      }
      if (row.cells[3].value == 'NIE') {
        row.cells[3].style.textBrush = PdfBrushes.red;
        row.cells[3].style.font = boldFont;
      }
    }

    final availableHeight = page.getClientSize().height - currentY - 10;
    dataGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, currentY, pageWidth, availableHeight),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    );

    final bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Opens the file (PDF or HTML) in the browser (Web) or viewer (Mobile).
  void openFile(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      openFileFromBytes(bytes, fileName);
    } else {
      // Mobile implementation would go here (e.g. open_file package)
      debugPrint('Opening $fileName on mobile is not yet implemented.');
    }
  }

  /// Generates the CCP-3 Cooling Report with custom header and 3-box limits layout.
  Future<Uint8List> generateCcp3Report({
    required List<Map<String, dynamic>> logs,
    required String userName,
    required String date,
    Uint8List? venueLogo,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    final params = _Ccp3ReportParams(
      logs: logs,
      userName: userName,
      date: date,
      venueLogo: venueLogo,
      fontBytes: fontData.buffer.asUint8List(),
      boldFontBytes: boldFontData.buffer.asUint8List(),
    );

    if (kIsWeb || !useIsolate) {
      return await _generateCcp3PdfIsolate(params);
    }
    return await compute(_generateCcp3PdfIsolate, params);
  }

  static Future<Uint8List> _generateCcp3PdfIsolate(_Ccp3ReportParams params) async {
    debugPrint('🔵 _generateCcp3PdfIsolate: Start');
    final document = PdfDocument();
    
    // Set margins to match a standard printable sheet (approx 1 cm/0.5 inch)
    document.pageSettings.margins.all = 20;

    final page = document.pages.add();
    final graphics = page.graphics;
    
    // Fonts
    final font = _createRegularFont(params.fontBytes, 9);
    final boldFont = _createBoldFont(params.boldFontBytes, 10);
    final titleFont = _createBoldFont(params.boldFontBytes, 14);

    // 1. Header Grid (Restaurant Info, Title, Responsible)
    final topGrid = PdfGrid();
    topGrid.columns.add(count: 3);
    
    // Safety check for page width
    double pageWidth = page.getClientSize().width;
    if (pageWidth <= 0) {
      debugPrint('⚠️ Page width is <= 0 ($pageWidth), defaulting to 500');
      pageWidth = 500;
    }
    
    debugPrint('🔵 _generateCcp3PdfIsolate: Page Width = $pageWidth');
    
    topGrid.columns[0].width = pageWidth * 0.35;
    topGrid.columns[1].width = pageWidth * 0.35;
    topGrid.columns[2].width = pageWidth * 0.30;

    final topRow = topGrid.rows.add();
    
    // Cell 1: Restaurant Info
    topRow.cells[0].value = 'Restauracja „Mięso i Piana”\nul. Energetyków 18A,\n37-450 Stalowa Wola';
    topRow.cells[0].style.font = boldFont;
    topRow.cells[0].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);
    
    // Cell 2: Title
    topRow.cells[1].value = 'Arkusz monitorowania CCP-3';
    topRow.cells[1].style.font = titleFont;
    topRow.cells[1].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);

    // Cell 3: Responsible
    topRow.cells[2].value = 'Odpowiedzialny:\nUpoważniony pracownik';
    topRow.cells[2].style.font = font;
    topRow.cells[2].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);

    // Set height for consistency
    topRow.height = 50;

    debugPrint('🔵 _generateCcp3PdfIsolate: Drawing header...');
    final topLayout = topGrid.draw(page: page, bounds: Rect.fromLTWH(0, 0, pageWidth, 0));
    var currentY = topLayout!.bounds.bottom;

    // 2. Limits Grid
    final limitGrid = PdfGrid();
    limitGrid.columns.add(count: 3);
    limitGrid.columns[0].width = pageWidth * 0.45; // Target
    limitGrid.columns[1].width = pageWidth * 0.25; // Tolerance
    limitGrid.columns[2].width = pageWidth * 0.30; // Critical

    final limitRow = limitGrid.rows.add();
    
    // Limit 1: Target
    limitRow.cells[0].value = 'Wartość docelowa\n20°C w 2 godz.';
    limitRow.cells[0].style.backgroundBrush = PdfBrushes.white; // Explicit white (or light green if requested)
    limitRow.cells[0].style.font = boldFont;
    limitRow.cells[0].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);

    // Limit 2: Tolerance
    limitRow.cells[1].value = 'Tolerancja\n+ 10°C';
    limitRow.cells[1].style.font = boldFont;
    limitRow.cells[1].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);

    // Limit 3: Critical
    limitRow.cells[2].value = 'Wartość krytyczna\n30°C';
    limitRow.cells[2].style.font = boldFont;
    limitRow.cells[2].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);

    limitRow.height = 35; // Compact height

    final limitLayout = limitGrid.draw(page: page, bounds: Rect.fromLTWH(0, currentY, pageWidth, 0));
    currentY = limitLayout!.bounds.bottom;

    // --- Data Grid ---
    debugPrint('🔵 _generateCcp3PdfIsolate: Preparing data grid for ${params.logs.length} logs');
    final grid = PdfGrid();
    grid.columns.add(count: 7);
    
    // Column Mapping & Widths
    grid.columns[0].width = pageWidth * 0.14;
    grid.columns[1].width = pageWidth * 0.22;
    grid.columns[2].width = pageWidth * 0.12;
    grid.columns[3].width = pageWidth * 0.12;
    grid.columns[4].width = pageWidth * 0.10;
    grid.columns[5].width = pageWidth * 0.20;
    grid.columns[6].width = pageWidth * 0.10;

    // Header Row
    final header = grid.headers.add(1)[0];
    header.height = 40; // Taller header for multi-line text
    
    final headers = [
      'Data/godz\nrozpoczęcia\nschładzania',
      'Rodzaj\npierogów',
      'Godz.\nzakończenia\nschładzania',
      'Wartość\ntemperatury',
      'Zgodność z\nustaleniami',
      'Działania\nkorygujące',
      'Podpis'
    ];

    for(int i=0; i<headers.length; i++) {
      header.cells[i].value = headers[i];
      header.cells[i].style.backgroundBrush = PdfSolidBrush(PdfColor(229, 229, 229)); // Light gray like Excel
      header.cells[i].style.font = boldFont;
      header.cells[i].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);
    }

    // Data Rows
    for (var log in params.logs) {
      final data = log['data'] as Map<String, dynamic>;
      final row = grid.rows.add();
      
      // 1. Start Date/Time
      final prepDate = data['prep_date']?.toString() ?? '-';
      final startTime = data['start_time']?.toString() ?? '-';
      String dateStr = prepDate; 
      try {
         final dt = DateTime.parse(prepDate);
         dateStr = '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}';
      } catch(_) {}
      row.cells[0].value = '$dateStr\n$startTime';

      // 2. Product
      row.cells[1].value = data['product_name']?.toString() ?? '-';

      // 3. End Time
      row.cells[2].value = data['end_time']?.toString() ?? '-';

      // 4. Temp (New 'temperature' or fallback to 'temp_2h'/'end_temp')
      final tempVal = data['temperature'] ?? data['temp_2h'] ?? data['end_temp'];
      row.cells[3].value = tempVal != null ? '$tempVal' : '-'; 
      // Ensure text is centered
      row.cells[3].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);

      // 5. Compliance
      bool isCompliant = false;
      if (data.containsKey('compliance')) {
         isCompliant = data['compliance'] == true;
      } else {
         if (tempVal != null) {
            final t = double.tryParse(tempVal.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
            if (t != null) isCompliant = t <= 30.0;
         }
      }
      
      row.cells[4].value = isCompliant ? 'TAK' : 'NIE';
      if (!isCompliant) {
        row.cells[4].style.textBrush = PdfBrushes.red;
        row.cells[4].style.font = boldFont;
      }

      // 6. Corrective Actions (New 'corrective_actions' or fallback to 'comments')
      final comments = data['corrective_actions'] ?? data['comments'];
      row.cells[5].value = comments?.toString() ?? '';

      // 7. Signature (Initials)
      row.cells[6].value = ''; 
    }
    
    // Add empty rows
    for(int i=0; i<15; i++) {
       final row = grid.rows.add();
       for(int j=0; j<7; j++) row.cells[j].value = '';
       row.height = 20;
    }

    // Set Cell Style for all rows
    for(int i=0; i<grid.rows.count; i++) {
      final row = grid.rows[i];
      for(int j=0; j<row.cells.count; j++) {
        // Center align everything except maybe Product Name (1) and Actions (5)
        if (j != 1 && j != 5) {
           row.cells[j].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);
        } else {
           row.cells[j].stringFormat = PdfStringFormat(alignment: PdfTextAlignment.left, lineAlignment: PdfVerticalAlignment.middle);
           row.cells[j].style.cellPadding = PdfPaddings(left: 4, right: 2, top: 2, bottom: 2);
        }
        // Explicitly set font for cells if not already set (compliance warning sets it)
        if (row.cells[j].style.font == null) {
          row.cells[j].style.font = font;
        }
      }
    }

    debugPrint('🔵 _generateCcp3PdfIsolate: Drawing data grid...');
    grid.draw(page: page, bounds: Rect.fromLTWH(0, currentY, pageWidth, 0));

    // Footer Signature Line
    final footerY = page.getClientSize().height - 40;
    graphics.drawString('Sprawdził/zatwierdził: .................................................', boldFont, bounds: Rect.fromLTWH(0, footerY, 400, 20));
    graphics.drawString('(Data/podpis)', font, bounds: Rect.fromLTWH(200, footerY + 15, 100, 20));
    
    debugPrint('🔵 _generateCcp3PdfIsolate: Saving document...');
    final List<int> bytes = await document.save();
    document.dispose();
    debugPrint('🟢 _generateCcp3PdfIsolate: Done! ${bytes.length} bytes generated.');
    return Uint8List.fromList(bytes);
  }

  static PdfFont _createRegularFont(Uint8List fontBytes, double size) {
    try {
      return PdfTrueTypeFont(fontBytes, size);
    } catch (_) {
      return PdfStandardFont(PdfFontFamily.helvetica, size);
    }
  }

  static PdfFont _createBoldFont(Uint8List fontBytes, double size) {
    try {
      return PdfTrueTypeFont(fontBytes, size);
    } catch (_) {
      return PdfStandardFont(
        PdfFontFamily.helvetica,
        size,
        style: PdfFontStyle.bold,
      );
    }
  }
}

class _Ccp3ReportParams {
  final List<Map<String, dynamic>> logs;
  final String userName;
  final String date;
  final Uint8List? venueLogo;
  final Uint8List fontBytes;
  final Uint8List boldFontBytes;

  _Ccp3ReportParams({
    required this.logs,
    required this.userName,
    required this.date,
    this.venueLogo,
    required this.fontBytes,
    required this.boldFontBytes,
  });
}

class _Ccp1TemperatureReportParams {
  final String sensorName;
  final String userName;
  final String monthLabel;
  final List<List<String>> rows;
  final Uint8List fontBytes;
  final Uint8List boldFontBytes;

  _Ccp1TemperatureReportParams({
    required this.sensorName,
    required this.userName,
    required this.monthLabel,
    required this.rows,
    required this.fontBytes,
    required this.boldFontBytes,
  });
}

class _PdfGenerationParams {
  final String title;
  final FormDefinition definition;
  final Map<String, dynamic> data;
  final String userName;
  final String date;
  final Map<String, Uint8List> images;
  final Uint8List fontBytes;
  final Uint8List boldFontBytes;

  _PdfGenerationParams({
    required this.title,
    required this.definition,
    required this.data,
    required this.userName,
    required this.date,
    required this.images,
    required this.fontBytes,
    required this.boldFontBytes,
  });
}

class _PdfTableParams {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final String userName;
  final String dateRange;
  final Uint8List fontBytes;
  final Uint8List boldFontBytes;

  _PdfTableParams({
    required this.title,
    required this.columns,
    required this.rows,
    required this.userName,
    required this.dateRange,
    required this.fontBytes,
    required this.boldFontBytes,
  });
}

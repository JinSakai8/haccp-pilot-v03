import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:haccp_pilot/features/shared/models/form_definition.dart';
import 'package:haccp_pilot/core/services/file_opener.dart'; // Conditional import helper

/// Service for generating PDF reports.
/// Uses [compute] to run heavy PDF generation in a separate isolate.
class PdfService {
  
  /// Generates a PDF report for a generic form (GMP/GHP).
  Future<List<int>> generateFormReport({
    required String title,
    required FormDefinition definition,
    required Map<String, dynamic> data,
    required String userName,
    required String date,
    Uint8List? logoBytes,
  }) async {
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
    );

    // compute doesn't work on web, so run directly
    if (kIsWeb) {
      return await _generatePdfIsolate(params);
    }
    return await compute(_generatePdfIsolate, params);
  }

  /// The static method that runs in an isolate.
  static Future<List<int>> _generatePdfIsolate(_PdfGenerationParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

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
    return bytes;
  }

  /// Generates a tabular report (e.g. Monthly Waste Log, Temperature Log).
  Future<List<int>> generateTableReport({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    required String userName,
    required String dateRange,
  }) async {
    final params = _PdfTableParams(
      title: title,
      columns: columns,
      rows: rows,
      userName: userName,
      dateRange: dateRange,
    );

    if (kIsWeb) {
      return await _generateTablePdfIsolate(params);
    }
    return await compute(_generateTablePdfIsolate, params);
  }

  static Future<List<int>> _generateTablePdfIsolate(_PdfTableParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

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
    return bytes;
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
  Future<List<int>> generateCcp3Report({
    required List<Map<String, dynamic>> logs,
    required String userName,
    required String date,
    Uint8List? venueLogo,
  }) async {
    final params = _Ccp3ReportParams(
      logs: logs,
      userName: userName,
      date: date,
      venueLogo: venueLogo,
    );

    if (kIsWeb) {
      return await _generateCcp3PdfIsolate(params);
    }
    return await compute(_generateCcp3PdfIsolate, params);
  }

  static Future<List<int>> _generateCcp3PdfIsolate(_Ccp3ReportParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final largeFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);

    // --- Header Row 1: Facility & Title ---
    if (params.venueLogo != null) {
      final logoBitmap = PdfBitmap(params.venueLogo!);
      graphics.drawImage(logoBitmap, Rect.fromLTWH(0, 0, 60, 60));
    }
    
    // Restaurant Info (Mocked or passed - for now hardcoded as per image)
    graphics.drawString(
      'Restauracja "Mięso i Piana"\nul. Energetyków 18A,\n37-450 Stalowa Wola', 
      font, 
      bounds: Rect.fromLTWH(params.venueLogo != null ? 70 : 0, 10, 200, 50)
    );

    // Title Box
    final titleBounds = Rect.fromLTWH(200, 0, 315, 60);
    graphics.drawRectangle(bounds: titleBounds, pen: PdfPens.black);
    graphics.drawString(
      'Arkusz monitorowania CCP-3', 
      largeFont, 
      bounds: Rect.fromLTWH(210, 10, 300, 20),
    );
    graphics.drawString(
      'Odpowiedzialny:\nUpoważniony pracownik', 
      font, 
      bounds: Rect.fromLTWH(360, 10, 150, 40),
      format: PdfStringFormat(alignment: PdfTextAlignment.right)
    );

    // --- Header Row 2: Limits (Target, Tolerance, Critical) ---
    final yStart = 70.0;
    final boxWidth = 515 / 3; // Approx 171
    final boxHeight = 40.0;

    // Box 1: Target
    graphics.drawRectangle(bounds: Rect.fromLTWH(0, yStart, boxWidth, boxHeight), brush: PdfBrushes.lightGreen);
    graphics.drawRectangle(bounds: Rect.fromLTWH(0, yStart, boxWidth, boxHeight), pen: PdfPens.black); // Border
    graphics.drawString('Wartość docelowa', boldFont, bounds: Rect.fromLTWH(5, yStart + 5, boxWidth, 20), format: PdfStringFormat(alignment: PdfTextAlignment.center));
    graphics.drawString('20°C w 2 godz.', font, bounds: Rect.fromLTWH(5, yStart + 20, boxWidth, 20), format: PdfStringFormat(alignment: PdfTextAlignment.center));

    // Box 2: Tolerance
    graphics.drawRectangle(bounds: Rect.fromLTWH(boxWidth, yStart, boxWidth, boxHeight), brush: PdfBrushes.lightYellow);
    graphics.drawRectangle(bounds: Rect.fromLTWH(boxWidth, yStart, boxWidth, boxHeight), pen: PdfPens.black);
    graphics.drawString('Tolerancja', boldFont, bounds: Rect.fromLTWH(boxWidth + 5, yStart + 5, boxWidth, 20), format: PdfStringFormat(alignment: PdfTextAlignment.center));
    graphics.drawString('+ 10°C', font, bounds: Rect.fromLTWH(boxWidth + 5, yStart + 20, boxWidth, 20), format: PdfStringFormat(alignment: PdfTextAlignment.center));

    // Box 3: Critical
    graphics.drawRectangle(bounds: Rect.fromLTWH(boxWidth * 2, yStart, boxWidth, boxHeight), brush: PdfBrushes.mistyRose); // Light Red-ish
    graphics.drawRectangle(bounds: Rect.fromLTWH(boxWidth * 2, yStart, boxWidth, boxHeight), pen: PdfPens.black);
    graphics.drawString('Wartość krytyczna', boldFont, bounds: Rect.fromLTWH(boxWidth * 2 + 5, yStart + 5, boxWidth, 20), format: PdfStringFormat(alignment: PdfTextAlignment.center));
    graphics.drawString('30°C', font, bounds: Rect.fromLTWH(boxWidth * 2 + 5, yStart + 20, boxWidth, 20), format: PdfStringFormat(alignment: PdfTextAlignment.center));

    // --- Data Table ---
    final grid = PdfGrid();
    grid.columns.add(count: 7);
    
    // Column widths relative to total
    // 0: Start (15%), 1: Product (20%), 2: End Time (10%), 3: Temp (10%), 4: Compliance (10%), 5: Actions (20%), 6: Sign (15%)
    
    final header = grid.headers.add(1)[0];
    header.cells[0].value = 'Data/godz\nrozpoczęcia';
    header.cells[1].value = 'Rodzaj\nproduktu';
    header.cells[2].value = 'Godz.\nkoniec';
    header.cells[3].value = 'Temp.\n(2h)';
    header.cells[4].value = 'Zgodność';
    header.cells[5].value = 'Działania\nkorygujące';
    header.cells[6].value = 'Podpis';

    // Style header
    for(int i=0; i<header.cells.count; i++) {
      header.cells[i].style.backgroundBrush = PdfBrushes.lightGray;
      header.cells[i].style.font = boldFont;
    }

    // Add Data Rows
    for (var log in params.logs) {
      final data = log['data'] as Map<String, dynamic>;
      final row = grid.rows.add();
      
      // 1. Start Date/Time
      // We expect 'prep_date' (YYYY-MM-DD or similar) and 'start_time' (HH:MM or TimeOfDay)
      // If data structure varies, we handle gracefully.
      final prepDate = data['prep_date']?.toString() ?? '-';
      final startTime = data['start_time']?.toString() ?? '-';
      // Format nicely if possible, e.g. "12.02 10:00"
      // Check if prepDate is full timestamp
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

      // 4. Temp (2h check)
      final tempVal = data['temp_2h'];
      row.cells[3].value = tempVal != null ? '$tempVal°C' : '-';

      // 5. Compliance
      // Logic: Target 20, Tolerance +10 = Max 30.
      bool isCompliant = false;
      if (tempVal != null && (tempVal is num || double.tryParse(tempVal.toString()) != null)) {
         final t = tempVal is num ? tempVal : double.parse(tempVal.toString());
         isCompliant = t <= 30.0;
      }
      row.cells[4].value = isCompliant ? 'TAK' : 'NIE';
      if (!isCompliant) {
        row.cells[4].style.textBrush = PdfBrushes.red;
        row.cells[4].style.font = boldFont;
      }

      // 6. Corrective Actions (comments)
      final comments = data['comments'] ?? data['notes'] ?? '';
      row.cells[5].value = comments.toString();

      // 7. Signature (User who created)
      // Since logs usually map user_id -> Name via repository logic before reaching here, or we use userName param?
      // For now, let's use the main userName passed to function if it matches, or simplistic placeholder.
      // Often the report is for one user (the one generating), or we'd need to fetch user names.
      // Assuming 'user_id' is in log.
      row.cells[6].value = 'User ${log['user_id'].toString().substring(0,4)}...'; // Simplified
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 120, 0, 0), // Start after header
    );

    // Footer
    final footerY = page.getClientSize().height - 30;
    graphics.drawString('Sprawdził/zatwierdził: ...........................', font, bounds: Rect.fromLTWH(0, footerY, 300, 20));

    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }
}

class _Ccp3ReportParams {
  final List<Map<String, dynamic>> logs;
  final String userName;
  final String date;
  final Uint8List? venueLogo;

  _Ccp3ReportParams({
    required this.logs,
    required this.userName,
    required this.date,
    this.venueLogo,
  });
}

class _PdfGenerationParams {
  final String title;
  final FormDefinition definition;
  final Map<String, dynamic> data;
  final String userName;
  final String date;
  final Map<String, Uint8List> images;

  _PdfGenerationParams({
    required this.title,
    required this.definition,
    required this.data,
    required this.userName,
    required this.date,
    required this.images,
  });
}

class _PdfTableParams {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final String userName;
  final String dateRange;

  _PdfTableParams({
    required this.title,
    required this.columns,
    required this.rows,
    required this.userName,
    required this.dateRange,
  });
}

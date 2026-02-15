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

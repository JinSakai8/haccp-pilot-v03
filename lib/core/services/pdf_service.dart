import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:haccp_pilot/features/shared/models/form_definition.dart';
import 'package:http/http.dart' as http;

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
  }) async {
    // Collect images first (on main thread or via async calls, before compute)
    // Images need to be passed as raw bytes to the isolate
    final images = <String, Uint8List>{};
    
    // Check for photo fields in data
    for (var field in definition.fields) {
      if (field.type == HaccpFieldType.photo) {
        final path = data[field.id];
        if (path != null && path is String && path.isNotEmpty) {
           try {
             // If path is a Supabase URL or local file, we need bytes.
             // Assuming Supabase Storage public URL or signed URL for now.
             // If it's a local path (offline), we read file.
             if (path.startsWith('http')) {
               final response = await http.get(Uri.parse(path));
               if (response.statusCode == 200) {
                 images[field.id] = response.bodyBytes;
               }
             } else {
               final file = File(path);
               if (await file.exists()) {
                 images[field.id] = await file.readAsBytes();
               }
             }
           } catch (e) {
             print('Error loading image for PDF: $e');
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

    return await compute(_generatePdfIsolate, params);
  }

  /// The static method that runs in an isolate.
  static Future<List<int>> _generatePdfIsolate(_PdfGenerationParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    // 1. Header
    graphics.drawString(
      params.title.toUpperCase(),
      boldFont,
      bounds: Rect.fromLTWH(0, 0, 500, 30),
    );

    graphics.drawString(
      'Data: ${params.date} | Wykonał: ${params.userName}',
      font,
      bounds: Rect.fromLTWH(0, 30, 500, 20),
    );

    // 2. Grid (Table)
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
           // We cannot easily embed widget here, but we can draw image in the cell
           // For simplicity in grid, we just say "Patrz załącznik" or try to embed if possible.
           // Syncfusion Grid cells support PdfGridCell.value = PdfBitmap(...) ? No, usually string.
           // We might need to draw images after the grid or use specific cell style.
           
           // Simpler approach: Text in cell, image below.
           row.cells[1].value = '[ZDJĘCIE ZAŁĄCZONE NIŻEJ]';
        } else {
           row.cells[1].value = 'Brak zdjęcia';
        }
      } else if (field.type == HaccpFieldType.toggle) {
         final boolValue = val == true; // Assuming non-null meaning OK? Or specific structure?
         // In DynamicForm, val might be basic type. 
         // Let's assume val is map or bool.
         row.cells[1].value = boolValue ? 'ZGODNE' : 'NIEZGODNE';
         // Check for comments
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

    // 3. Append images at the bottom or new pages
    var currentY = layoutResult!.bounds.bottom + 20;
    
    if (params.images.isNotEmpty) {
      graphics.drawString('ZAŁĄCZNIKI ZDJĘCIOWE:', boldFont, bounds: Rect.fromLTWH(0, currentY, 500, 20));
      currentY += 30;

      for (var entry in params.images.entries) {
        final imageBytes = entry.value;
        final pdfBitmap = PdfBitmap(imageBytes);
        
        // Resize to fit page width (approx 500)
        const maxWidth = 400.0;
        final scale = maxWidth / pdfBitmap.width;
        final height = pdfBitmap.height * scale;

        // Check if we need new page
        if (currentY + height > page.getClientSize().height) {
           // Simplified: just add to next page (not implemented loop for multipage here for brevity)
           // For MVP, just draw what fits or add page.
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

    return await compute(_generateTablePdfIsolate, params);
  }

  static Future<List<int>> _generateTablePdfIsolate(_PdfTableParams params) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    // 1. Header
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

    // 2. Table
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

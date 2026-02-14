import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String filePath;

  const PdfPreviewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Podgląd PDF'),
      backgroundColor: AppTheme.background,
      body: SfPdfViewer.file(
        File(filePath),
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Błąd ładowania PDF: ${details.error}')),
          );
        },
      ),
    );
  }
}

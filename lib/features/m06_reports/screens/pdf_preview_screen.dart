import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String filePath;

  const PdfPreviewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: const HaccpTopBar(title: 'Podgląd PDF'),
        backgroundColor: AppTheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.web_asset_off, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Podgląd PDF niedostępny w przeglądarce',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // On mobile, we could use SfPdfViewer.file, but since we removed dart:io,
    // we need to handle this differently. For now, show a placeholder.
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Podgląd PDF'),
      backgroundColor: AppTheme.background,
      body: Center(
        child: Text(
          'Plik: $filePath',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

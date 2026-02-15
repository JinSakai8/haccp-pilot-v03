import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String filePath;

  const PdfPreviewScreen({super.key, required this.filePath});

  Future<void> _shareFile() async {
    if (await File(filePath).exists()) {
      await Share.shareXFiles([XFile(filePath)], text: 'Raport HACCP');
    }
  }

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

    return Scaffold(
      appBar: HaccpTopBar(
        title: 'Podgląd PDF',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareFile(),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}

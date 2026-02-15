
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:haccp_pilot/core/services/storage_service.dart';
import 'package:haccp_pilot/core/constants/design_tokens.dart';

class HaccpCameraScreen extends StatefulWidget {
  final String venueId;

  const HaccpCameraScreen({super.key, required this.venueId});

  @override
  State<HaccpCameraScreen> createState() => _HaccpCameraScreenState();
}

class _HaccpCameraScreenState extends State<HaccpCameraScreen> {
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _uploadError;
  // bool _cameraInitialized = false; // Not used for now in Web/Placeholder mode

  @override
  void initState() {
    super.initState();
    // _initCamera(); // Not needed for Web file picker approach
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _imageBytes = result.files.single.bytes;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() => _uploadError = "Błąd wyboru pliku: $e");
    }
  }

  Future<void> _uploadAndReturn() async {
    if (_imageBytes == null) return;
    
    setState(() => _isUploading = true);
    
    final uploadedPath = await StorageService.uploadWastePhotoBytes(_imageBytes!, widget.venueId);
    
    if (mounted) {
      setState(() => _isUploading = false);
      if (uploadedPath != null) {
        if (kDebugMode) print("Returning path: $uploadedPath");
        Navigator.pop(context, uploadedPath);
      } else {
        setState(() => _uploadError = "Błąd wysyłania. Spróbuj ponownie.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If image is picked, show preview and confirmation
    if (_imageBytes != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Image.memory(_imageBytes!, fit: BoxFit.contain),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.black54,
                child: Column(
                  children: [
                    if (_uploadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_uploadError!, style: const TextStyle(color: HaccpDesignTokens.error)),
                      ),
                    
                    if (_isUploading)
                      const CircularProgressIndicator()
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() => _imageBytes = null),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('ZMIEŃ', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _uploadAndReturn,
                            icon: const Icon(Icons.check),
                            label: const Text('ZATWIERDŹ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HaccpDesignTokens.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Web or Fallback Mode
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              'Dodaj zdjęcie odpadu',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text(kIsWeb ? 'WYBIERZ PLIK' : 'WYBIERZ Z GALERII'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HaccpDesignTokens.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            if (!kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '(Kamera dostępna tylko na urządzeniach mobilnych)',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

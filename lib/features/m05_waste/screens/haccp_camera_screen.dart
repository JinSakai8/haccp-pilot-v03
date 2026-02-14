
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haccp_pilot/core/services/storage_service.dart';
import 'package:haccp_pilot/core/widgets/haccp_long_press_button.dart';

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
  bool _cameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() => _uploadError = "Kamera nie jest dostępna w przeglądarce");
      return;
    }
    // On mobile, camera would be initialized here
    // For now, show placeholder since camera plugin requires dart:io
    setState(() {
      _uploadError = "Kamera wymaga urządzenia mobilnego";
    });
  }

  Future<void> _uploadAndReturn() async {
    if (_imageBytes == null) return;
    
    setState(() => _isUploading = true);
    
    final uploadedPath = await StorageService.uploadWastePhotoBytes(_imageBytes!, widget.venueId);
    
    if (mounted) {
      setState(() => _isUploading = false);
      if (uploadedPath != null) {
        Navigator.pop(context, uploadedPath);
      } else {
        setState(() => _uploadError = "Błąd wysyłania. Spróbuj ponownie.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show web/unavailable message
    if (kIsWeb || !_cameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white54),
                const SizedBox(height: 24),
                Text(
                  _uploadError ?? 'Inicjalizacja kamery...',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('WRÓĆ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2661E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 60),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full camera UI for mobile (would need conditional import for camera package)
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: Text('Camera', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}


import 'dart:io';
import 'package:camera/camera.dart';
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

class _HaccpCameraScreenState extends State<HaccpCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _imageFile;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _uploadError = "Brak dostępnych kamer");
        return;
      }
      
      // Use back camera by default
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.jpeg 
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _uploadError = "Błąd inicjalizacji kamery: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera on resume if needed (mostly Android)
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final file = await _controller!.takePicture();
      setState(() {
        _imageFile = file;
        _uploadError = null;
      });
    } catch (e) {
      setState(() => _uploadError = "Błąd zapisu zdjęcia: $e");
    }
  }

  Future<void> _uploadAndReturn() async {
    if (_imageFile == null) return;
    
    setState(() => _isUploading = true);
    
    // Using StorageService to handle uploads
    // Note: Implementation Plan said Upload Logic in specific separate location or here.
    // Plan said: "Compress -> Upload -> Return Path"
    // Since we're in Review mode, we trigger upload now.
    
    final file = File(_imageFile!.path);
    final uploadedPath = await StorageService.uploadWastePhoto(file, widget.venueId);
    
    if (mounted) {
      setState(() => _isUploading = false);
      if (uploadedPath != null) {
        Navigator.pop(context, uploadedPath); // Return success path
      } else {
        setState(() => _uploadError = "Błąd wysyłania. Spróbuj ponownie.");
      }
    }
  }

  void _retry() {
    setState(() {
      _imageFile = null;
      _uploadError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no camera ready yet
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _uploadError != null 
              ? Text(_uploadError!, style: const TextStyle(color: Colors.red))
              : const CircularProgressIndicator(color: Color(0xFFD2661E)),
        ),
      );
    }

    // Review Mode
    if (_imageFile != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Image.file(
                  File(_imageFile!.path),
                  fit: BoxFit.contain,
                ),
              ),
              if (_isUploading)
                const LinearProgressIndicator(color: Color(0xFFD2661E)),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_uploadError!, 
                      style: const TextStyle(color: Colors.red, fontSize: 18)
                  ),
                ),
              if (!_isUploading)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: _retry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF9A825), // Warning/Orange
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 32, color: Colors.black),
                                Text("PONÓW", 
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: HaccpLongPressButton(
                          label: "ZATWIERDŹ",
                          icon: Icons.check,
                          height: 80,
                          color: const Color(0xFF2E7D32),
                          onCompleted: _uploadAndReturn,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Capture Mode (Full Screen Preview)
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          
          // Shutter Button (Bottom Center)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                    color: Colors.transparent,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD2661E), // Accent
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Back Button (Top Left)
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 40),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

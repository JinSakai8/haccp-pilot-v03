import 'dart:typed_data';
import 'package:haccp_pilot/core/services/app_logger.dart';

void openFileFromBytes(Uint8List bytes, String filename) {
  // Stub - do nothing on non-web platforms for now or throw unsupported
  AppLogger.warning('Opening files from bytes is not supported on this platform directly.');
}

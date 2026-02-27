import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void openFileFromBytes(Uint8List bytes, String filename) {
  Future<void>(() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Raport HACCP'),
      );
    } catch (e) {
      debugPrint('Failed to open/share file $filename: $e');
    }
  });
}

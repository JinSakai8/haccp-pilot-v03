import 'dart:html' as html;
import 'dart:typed_data';

void openFileFromBytes(Uint8List bytes, String filename) {
  String? mimeType;
  if (filename.toLowerCase().endsWith('.html')) {
    mimeType = 'text/html;charset=utf-8';
  } else if (filename.toLowerCase().endsWith('.pdf')) {
    mimeType = 'application/pdf';
  }

  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Force download using anchor element
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
  
  // Cleanup after a delay
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}

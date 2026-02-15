import 'dart:html' as html;
import 'dart:typed_data';

void openFileFromBytes(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Open in new tab
  html.window.open(url, "_blank");
  
  // Create anchor to force download/name if needed, but window.open is usually enough for viewing.
  // For saving with name:
  /*
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
  */
  
  // Cleanup after a delay (to allow time for open)
  Future.delayed(const Duration(seconds: 5), () {
    html.Url.revokeObjectUrl(url);
  });
}

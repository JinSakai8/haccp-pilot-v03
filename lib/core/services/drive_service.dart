import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class DriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];

  /// Uploads a file (as bytes) to the configured Google Drive folder.
  /// Returns the ID of the uploaded file.
  Future<String?> uploadReportBytes(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      debugPrint('Google Drive upload not supported on web');
      throw UnsupportedError('Google Drive upload nie jest dostępny w przeglądarce');
    }

    try {
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final credentials = ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
      final client = await clientViaServiceAccount(credentials, _scopes);
      final driveApi = drive.DriveApi(client);

      final folderId = dotenv.env['GOOGLE_DRIVE_FOLDER_ID'];
      if (folderId == null) {
        throw Exception('GOOGLE_DRIVE_FOLDER_ID not found in .env');
      }

      var driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [folderId];

      var media = drive.Media(
        Stream.fromIterable([bytes]),
        bytes.length,
      );

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      client.close();
      return result.id;
    } catch (e) {
      debugPrint('Drive Upload Error: $e');
      rethrow;
    }
  }

  /// Lists files in the configured Google Drive folder.
  Future<List<drive.File>> listFiles() async {
    if (kIsWeb) return [];

    try {
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final credentials = ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
      final client = await clientViaServiceAccount(credentials, _scopes);
      final driveApi = drive.DriveApi(client);
      final folderId = dotenv.env['GOOGLE_DRIVE_FOLDER_ID'];

      if (folderId == null) return [];

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: "files(id, name, createdTime, size, webContentLink)",
        orderBy: "createdTime desc"
      );

      client.close();
      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Drive List Error: $e');
      return [];
    }
  }
}

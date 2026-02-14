import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class DriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];

  /// Uploads a file to the configured Google Drive folder.
  /// Returns the ID of the uploaded file.
  Future<String?> uploadReport(File file, String fileName) async {
    try {
      // 1. Load credentials
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final credentials = ServiceAccountCredentials.fromJson(json.decode(credentialsJson));

      // 2. Get authenticated client
      final client = await clientViaServiceAccount(credentials, _scopes);
      final driveApi = drive.DriveApi(client);

      // 3. Get folder ID from .env
      final folderId = dotenv.env['GOOGLE_DRIVE_FOLDER_ID'];
      if (folderId == null) {
        throw Exception('GOOGLE_DRIVE_FOLDER_ID not found in .env');
      }

      // 4. Create File Metadata
      var driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [folderId];

      // 5. Create Media
      var media = drive.Media(file.openRead(), file.lengthSync());

      // 6. Upload
      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      client.close();
      return result.id;
    } catch (e) {
      print('Drive Upload Error: $e');
      rethrow;
    }
  }

  /// Lists files in the configured Google Drive folder.
  Future<List<drive.File>> listFiles() async {
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
      print('Drive List Error: $e');
      return [];
    }
  }
}

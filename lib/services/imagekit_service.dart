import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Service for uploading images to ImageKit
class ImageKitService {
  static final ImageKitService _instance = ImageKitService._internal();

  factory ImageKitService() {
    return _instance;
  }

  ImageKitService._internal();

  final String _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

  /// Get ImageKit credentials from environment variables
  String get _publicKey => (dotenv.env['IMAGEKIT_PUBLIC_KEY'] ?? '')
      .trim()
      .replaceAll('"', '')
      .replaceAll("'", "");
  String get _privateKey => (dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '')
      .trim()
      .replaceAll('"', '')
      .replaceAll("'", "");

  Future<String> uploadImage(
    File imageFile,
    String fileName, {
    String? folder,
  }) async {
    try {
      // 1. Credentials Diagnostics
      if (_publicKey.isEmpty || _privateKey.isEmpty) {
        throw Exception('ImageKit: Private or Public key is missing in .env');
      }

      if (kDebugMode) {
        String mask(String s) => s.length > 8
            ? '${s.substring(0, 4)}...${s.substring(s.length - 4)}'
            : 'INVALID';
        debugPrint('ImageKit Auth Diagnostics:');
        debugPrint(
          '  - Public Key: ${mask(_publicKey)} (Len: ${_publicKey.length})',
        );
        debugPrint(
          '  - Private Key: ${mask(_privateKey)} (Len: ${_privateKey.length})',
        );
      }

      if (!await imageFile.exists()) {
        throw Exception('ImageKit: File not found at ${imageFile.path}');
      }

      // 2. Prepare Request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // 3. Add Authentication Header
      // ImageKit: Private Key is the username, password is empty
      final String authString = '$_privateKey:';
      final String base64Auth = base64Encode(utf8.encode(authString));
      request.headers['Authorization'] = 'Basic $base64Auth';

      // 4. Add Fields
      request.fields['publicKey'] = _publicKey;
      request.fields['fileName'] = fileName;

      String folderPath = folder ?? 'bestmlewi/uploads';
      if (folderPath.startsWith('/')) folderPath = folderPath.substring(1);
      request.fields['folder'] = folderPath;
      request.fields['useUniqueFileName'] = 'true';

      // 5. Add File
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      debugPrint('ImageKit: Uploading $fileName to $folderPath...');

      // 6. Execute Request
      final response = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Image upload timed out'),
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
          if (jsonResponse.containsKey('url')) {
            final imageUrl = jsonResponse['url'] as String;
            debugPrint('ImageKit upload successful: $imageUrl');
            return imageUrl;
          } else {
            throw Exception('No URL in ImageKit response: $responseBody');
          }
        } catch (parseError) {
          throw Exception('Failed to parse ImageKit response: $parseError');
        }
      } else {
        debugPrint('ImageKit Error Response: $responseBody');
        // Check for specific error messages
        Map<String, dynamic>? errorJson;
        try {
          errorJson = jsonDecode(responseBody);
        } catch (_) {}

        String errorMessage = errorJson?['message'] ?? responseBody;
        throw Exception(
          'ImageKit upload failed (${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      debugPrint('ImageKit detail error: $e');
      throw Exception('Image upload error: $e');
    }
  }

  /// Delete image from ImageKit
  /// Takes the full ImageKit URL and extracts the fileId to delete
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (_publicKey.isEmpty || _privateKey.isEmpty) {
        debugPrint('ImageKit: Cannot delete, credentials missing');
        return;
      }

      // Extract fileId from URL
      final fileId = await _getFileIdFromUrl(imageUrl);

      if (fileId == null) {
        debugPrint('ImageKit: Could not find fileId for deletion: $imageUrl');
        return;
      }

      // Delete using Management API
      final deleteUrl = 'https://api.imagekit.io/v1/files/$fileId';

      final response = await http
          .delete(
            Uri.parse(deleteUrl),
            headers: {
              'Authorization': 'Basic ${_encodeCredentials(_privateKey)}',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('ImageKit: Image deleted successfully: $imageUrl');
      } else {
        debugPrint(
          'ImageKit: Delete failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('ImageKit: Error during deletion: $e');
    }
  }

  /// Get fileId from ImageKit URL using the List Files API
  Future<String?> _getFileIdFromUrl(String imageUrl) async {
    try {
      // Extract the file name from the URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.path.split('/').last;

      // Use List Files API to search for the file
      final listUrl = 'https://api.imagekit.io/v1/files';
      final queryParams = {'searchQuery': 'name="$fileName"'};

      final response = await http
          .get(
            Uri.parse(listUrl).replace(queryParameters: queryParams),
            headers: {
              'Authorization': 'Basic ${_encodeCredentials(_privateKey)}',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as List<dynamic>;
        if (jsonResponse.isNotEmpty) {
          // Find the exact match for the URL if possible, or just take the first
          for (var file in jsonResponse) {
            if (file['url'] == imageUrl) {
              return file['fileId'] as String?;
            }
          }
          final firstFile = jsonResponse[0] as Map<String, dynamic>;
          return firstFile['fileId'] as String?;
        }
      } else {
        debugPrint(
          'ImageKit: List files failed (${response.statusCode}): ${response.body}',
        );
      }
      return null;
    } catch (e) {
      debugPrint('ImageKit: Error getting fileId: $e');
      return null;
    }
  }

  /// Encode credentials for Basic Auth
  String _encodeCredentials(String privateKey) {
    return base64Encode(utf8.encode('$privateKey:'));
  }
}

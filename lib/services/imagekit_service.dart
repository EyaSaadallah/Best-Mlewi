import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
//hello
/// Service for uploading images to ImageKit
class ImageKitService {
  static final ImageKitService _instance = ImageKitService._internal();

  factory ImageKitService() {
    return _instance;
  }

  ImageKitService._internal();

  final String _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

  /// Get ImageKit credentials from environment variables
  String get _publicKey => dotenv.env['IMAGEKIT_PUBLIC_KEY'] ?? '';
  String get _privateKey => dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

  /// Upload image to ImageKit
  /// Returns the ImageKit URL of the uploaded image
  Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      if (_publicKey.isEmpty || _privateKey.isEmpty) {
        throw Exception('ImageKit credentials not configured in .env file');
      }

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add authentication
      request.headers['Authorization'] =
          'Basic ${_encodeCredentials(_privateKey)}';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add fields
      request.fields['publicKey'] = _publicKey;
      request.fields['fileName'] = fileName;
      request.fields['folder'] = '/bestmlewi/dishes';

      // Send request
      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Image upload timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();

        try {
          // Parse JSON response from ImageKit
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

          if (jsonResponse.containsKey('url')) {
            final imageUrl = jsonResponse['url'] as String;
            debugPrint('ImageKit upload successful: $imageUrl');
            return imageUrl;
          } else if (jsonResponse.containsKey('error')) {
            throw Exception('ImageKit error: ${jsonResponse['error']}');
          } else {
            throw Exception('No URL in ImageKit response: $responseBody');
          }
        } catch (parseError) {
          throw Exception(
            'Failed to parse ImageKit response: $parseError\nResponse: $responseBody',
          );
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
          'ImageKit upload failed: ${response.statusCode}\nResponse: $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }

  /// Encode credentials for Basic Auth
  String _encodeCredentials(String privateKey) {
    return base64Encode(utf8.encode('$privateKey:'));
  }
}

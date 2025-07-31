import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'base_service.dart';
import '../constants/file_constants.dart';
import '../exceptions/file_size_exception.dart';
import '../models/user.dart';

class UploadService extends BaseService {
  // Helper function to determine mime type
  static String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    final mimeTypeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'tiff': 'image/tiff',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
    };

    return mimeTypeMap[extension] ?? 'application/octet-stream';
  }

  static Future<String> uploadAvatar(File imageFile) async {
    try {
      // Check avatar file size limit
      final fileLength = await imageFile.length();
      if (!FileConstants.isAvatarSizeAllowed(fileLength)) {
        throw FileSizeException(FileConstants.avatarTooLarge);
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BaseService.baseUrl}/upload/avatar'),
      );

      // Add headers
      final headers = await BaseService.getHeaders();
      request.headers.addAll(headers);

      // Add file to request
      final fileStream = http.ByteStream(imageFile.openRead());

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'), // Adjust based on file type
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        // Return the avatar URL from response
        return jsonResponse['data']['user']['avatar'] ??
            jsonResponse['avatarUrl'];
      } else {
        throw Exception(
          'Failed to upload avatar: ${jsonResponse['message'] ?? responseBody}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadMessageFile(
    File file,
    String conversationId, {
    User? currentUser,
  }) async {
    try {
      // Check file size limit based on user premium status
      final fileLength = await file.length();
      final isPremium = currentUser?.isPremium ?? false;

      if (!FileConstants.isFileSizeAllowed(fileLength, isPremium)) {
        throw FileSizeException(
          FileConstants.getFileTooLargeMessage(isPremium),
          isPremiumRequired: !isPremium,
        );
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BaseService.baseUrl}/upload/attachment'),
      );

      // Add headers
      final headers = await BaseService.getHeaders();
      request.headers.addAll(headers);

      // Add file to request
      final fileStream = http.ByteStream(file.openRead());

      // Determine content type based on file extension
      final mimetype = getMimeType(file.path);

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: MediaType.parse(mimetype),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        // Return comprehensive file info including mimetype
        return {
          'url': jsonResponse['data']['file']['url'] ?? jsonResponse['fileUrl'],
          'name':
              jsonResponse['data']['file']['name'] ?? file.path.split('/').last,
          'size': jsonResponse['data']['file']['size'] ?? fileLength,
          'type':
              jsonResponse['data']['file']['type'] ??
              'file', // Use lowercase as fallback
          'mimetype':
              jsonResponse['data']['file']['mimeType'] ??
              mimetype, // Map from API mimeType to mimetype
        };
      } else {
        throw Exception(
          'Failed to upload file: ${jsonResponse['message'] ?? responseBody}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}

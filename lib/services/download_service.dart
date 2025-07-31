import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';

class DownloadService {
  static final Dio _dio = Dio();

  /// Request storage permission (required for Android)
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // Files are saved to app-specific directory which doesn't require permission
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+: No special permission needed for app-specific directories
        return true;
      } else {
        // Android 12 and below: Request storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  /// Get appropriate download directory
  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+: Use app-specific external files directory
        // This doesn't require WRITE_EXTERNAL_STORAGE permission
        try {
          Directory? directory = await getExternalStorageDirectory();
          if (directory != null) {
            final downloadDir = Directory('${directory.path}/Downloads');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          }
        } catch (e) {
          print('Failed to access external storage: $e');
        }

        // Fallback to app documents directory
        return await getApplicationDocumentsDirectory();
      } else {
        // Android 12 and below: Try to use public Downloads directory
        try {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Try to access public Downloads directory
            final publicDownloads = Directory('/storage/emulated/0/Download');
            if (await publicDownloads.exists()) {
              return publicDownloads;
            }

            // Fallback to app-specific Downloads
            final downloadDir = Directory('${directory.path}/Downloads');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          }
        } catch (e) {
          print('Failed to access external storage: $e');
        }

        // Final fallback to app documents directory
        return await getApplicationDocumentsDirectory();
      }
    } else {
      // iOS: Use documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Generate unique filename if file already exists
  static Future<String> _getUniqueFileName(
    Directory directory,
    String fileName,
  ) async {
    String name = path.basenameWithoutExtension(fileName);
    String extension = path.extension(fileName);

    File file = File('${directory.path}/$fileName');
    int counter = 1;

    while (await file.exists()) {
      String newFileName = '${name}_$counter$extension';
      file = File('${directory.path}/$newFileName');
      counter++;
    }

    return path.basename(file.path);
  }

  /// Download file with progress callback
  static Future<String?> downloadFile({
    required String url,
    required String fileName,
    Function(int received, int total)? onProgress,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        onError?.call('Storage permission denied');
        return null;
      }

      // Get download directory
      final downloadDir = await _getDownloadDirectory();

      // Generate unique filename
      final uniqueFileName = await _getUniqueFileName(downloadDir, fileName);
      final filePath = '${downloadDir.path}/$uniqueFileName';

      // Download file
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
        options: Options(headers: {'User-Agent': 'Mercury Chat App'}),
      );

      onSuccess?.call();
      return filePath;
    } catch (e) {
      onError?.call('Download failed: $e');
      return null;
    }
  }

  /// Download image from message attachment
  static Future<void> downloadImage({
    required BuildContext context,
    required String imageUrl,
    String? fileName,
  }) async {
    // Extract filename from URL if not provided
    fileName ??=
        _extractFileNameFromUrl(imageUrl) ??
        'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DownloadProgressDialog(fileName: fileName!, downloadUrl: imageUrl),
    );
  }

  /// Download video from message attachment
  static Future<void> downloadVideo({
    required BuildContext context,
    required String videoUrl,
    String? fileName,
  }) async {
    fileName ??=
        _extractFileNameFromUrl(videoUrl) ??
        'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DownloadProgressDialog(fileName: fileName!, downloadUrl: videoUrl),
    );
  }

  /// Download audio from message attachment
  static Future<void> downloadAudio({
    required BuildContext context,
    required String audioUrl,
    String? fileName,
  }) async {
    fileName ??=
        _extractFileNameFromUrl(audioUrl) ??
        'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DownloadProgressDialog(fileName: fileName!, downloadUrl: audioUrl),
    );
  }

  /// Download generic file from message attachment
  static Future<void> downloadGenericFile({
    required BuildContext context,
    required String fileUrl,
    String? fileName,
  }) async {
    fileName ??=
        _extractFileNameFromUrl(fileUrl) ??
        'file_${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DownloadProgressDialog(fileName: fileName!, downloadUrl: fileUrl),
    );
  }

  /// Extract filename from URL
  static String? _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return path.basename(uri.path);
    } catch (e) {
      return null;
    }
  }

  /// Get file size from URL
  static Future<int?> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLength = response.headers.value('content-length');
      return contentLength != null ? int.tryParse(contentLength) : null;
    } catch (e) {
      return null;
    }
  }
}

class DownloadProgressDialog extends StatefulWidget {
  final String fileName;
  final String downloadUrl;

  const DownloadProgressDialog({
    Key? key,
    required this.fileName,
    required this.downloadUrl,
  }) : super(key: key);

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _downloadedFilePath;
  int _receivedBytes = 0;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final filePath = await DownloadService.downloadFile(
        url: widget.downloadUrl,
        fileName: widget.fileName,
        onProgress: (received, total) {
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
            _progress = total > 0 ? received / total : 0.0;
          });
        },
        onSuccess: () {
          setState(() {
            _isDownloading = false;
            _isCompleted = true;
          });
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
            _hasError = true;
            _errorMessage = error;
          });
        },
      );

      if (filePath != null) {
        setState(() {
          _downloadedFilePath = filePath;
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isCompleted
                ? Icons.check_circle
                : _hasError
                ? Icons.error
                : Icons.download,
            color: _isCompleted
                ? Colors.green
                : _hasError
                ? Colors.red
                : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCompleted
                  ? 'Download Complete'
                  : _hasError
                  ? 'Download Failed'
                  : 'Downloading...',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fileName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            if (_totalBytes > 0)
              Text(
                '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)} (${(_progress * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],

          if (_isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File saved successfully',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
            if (_downloadedFilePath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Saved to: ${_downloadedFilePath!}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],

          if (_hasError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download failed',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_hasError)
          TextButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
                _isDownloading = true;
                _progress = 0.0;
              });
              _startDownload();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_isCompleted ? 'Done' : 'Cancel'),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'lib/services/upload_service.dart';
import 'lib/services/base_service.dart';

void main() async {
  print("Testing upload service...");

  // Test getMimeType function
  print("Testing getMimeType:");
  print("test.jpg -> ${UploadService.getMimeType('test.jpg')}");
  print("test.png -> ${UploadService.getMimeType('test.png')}");
  print("test.pdf -> ${UploadService.getMimeType('test.pdf')}");
  print("test.unknown -> ${UploadService.getMimeType('test.unknown')}");

  print("Upload service test completed!");
}

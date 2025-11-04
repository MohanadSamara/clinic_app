import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for handling file uploads and storage
/// Supports images, PDFs, and other document types
class FileService {
  static const List<String> imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];
  static const List<String> documentExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
  ];

  /// Save a file to local storage
  /// Returns the path where the file was saved
  Future<String> saveFile({
    required String sourcePath,
    required String fileName,
    String? subdirectory,
  }) async {
    try {
      if (kIsWeb) {
        // For web, files are typically handled differently
        // This is a placeholder for web implementation
        return sourcePath;
      }

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create subdirectory if specified
      String targetDir = directory.path;
      if (subdirectory != null) {
        targetDir = path.join(directory.path, subdirectory);
        final subDir = Directory(targetDir);
        if (!await subDir.exists()) {
          await subDir.create(recursive: true);
        }
      }

      // Generate unique filename if file already exists
      String targetPath = path.join(targetDir, fileName);
      final file = File(targetPath);

      if (await file.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(fileName);
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        fileName = '${nameWithoutExt}_$timestamp$extension';
        targetPath = path.join(targetDir, fileName);
      }

      // Copy the file
      final sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);

      return targetPath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Save an image file specifically
  Future<String> saveImage({
    required String sourcePath,
    required String fileName,
  }) async {
    return await saveFile(
      sourcePath: sourcePath,
      fileName: fileName,
      subdirectory: 'images',
    );
  }

  /// Save a document file specifically
  Future<String> saveDocument({
    required String sourcePath,
    required String fileName,
  }) async {
    return await saveFile(
      sourcePath: sourcePath,
      fileName: fileName,
      subdirectory: 'documents',
    );
  }

  /// Delete a file from storage
  Future<bool> deleteFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web implementation would be different
        return true;
      }

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Check if a file exists
  Future<bool> fileExists(String filePath) async {
    try {
      if (kIsWeb) {
        return true; // Placeholder for web
      }

      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      if (kIsWeb) {
        return 0; // Placeholder for web
      }

      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get file extension
  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Check if file is an image
  bool isImage(String filePath) {
    final ext = getFileExtension(filePath);
    return imageExtensions.contains(ext);
  }

  /// Check if file is a document
  bool isDocument(String filePath) {
    final ext = getFileExtension(filePath);
    return documentExtensions.contains(ext);
  }

  /// Get file type category
  String getFileType(String filePath) {
    if (isImage(filePath)) return 'image';
    if (isDocument(filePath)) return 'document';
    return 'other';
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clean up old files (optional maintenance function)
  Future<void> cleanupOldFiles({
    required String subdirectory,
    required Duration olderThan,
  }) async {
    try {
      if (kIsWeb) return;

      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory(path.join(directory.path, subdirectory));

      if (!await targetDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(olderThan);
      final files = targetDir.listSync();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Log error but don't throw
      print('Error cleaning up old files: $e');
    }
  }
}

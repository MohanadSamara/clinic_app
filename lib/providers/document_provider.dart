// lib/providers/document_provider.dart
// Document Provider using Supabase as the single source of truth
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:universal_html/universal_html.dart' as html;
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_complete_service.dart';
import '../models/document.dart';
import '../models/notification.dart' as app_notification;
import '../providers/auth_provider.dart';

// Data class for encryption parameters
class EncryptData {
  final List<int> data;
  final String keyString;

  EncryptData(this.data, this.keyString);
}

/// DocumentProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: documents, audit_logs, notifications, pets
///
/// All database operations now use Supabase client exclusively.
/// SQLite (DBHelper) has been completely removed.
class DocumentProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  // Web storage using SharedPreferences (persists across page refreshes)
  static Future<void> _saveWebFile(String key, List<int> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(data);
    await prefs.setString('web_file_$key', encoded);
  }

  static Future<List<int>?> _loadWebFile(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('web_file_$key');
    if (encoded != null) {
      return base64Decode(encoded);
    }
    return null;
  }

  static Future<void> _deleteWebFile(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('web_file_$key');
  }

  // Top-level function for background encryption
  static Future<List<int>> _encryptDataInBackground(EncryptData params) async {
    final key = encrypt.Key(base64.decode(params.keyString));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(params.data, iv: iv);
    // Return IV + encrypted data
    return iv.bytes + encrypted.bytes;
  }

  // Top-level function for background checksum calculation
  static Future<String> _calculateChecksumInBackground(List<int> data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  // Top-level function for background decryption
  static Future<List<int>> _decryptDataInBackground(EncryptData params) async {
    final key = encrypt.Key(base64.decode(params.keyString));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final iv = encrypt.IV(Uint8List.fromList(params.data.sublist(0, 16)));
    final encrypted = encrypt.Encrypted(
      Uint8List.fromList(params.data.sublist(16)),
    );

    return encrypter.decryptBytes(encrypted, iv: iv);
  }

  List<Document> _documents = [];
  bool _isLoading = false;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;

  DocumentProvider(this._authProvider);

  // File size limits (in bytes)
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
    'txt',
  ];

  Future<void> loadDocuments({
    dynamic petId,
    dynamic userId,
    dynamic medicalRecordId,
  }) async {
    _isLoading = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      List<Map<String, dynamic>> data;

      final userIdStr = userId?.toString();
      final petIdStr = petId?.toString();
      final medicalRecordIdStr = medicalRecordId?.toString();

      if (medicalRecordIdStr != null) {
        data = await _supabaseService.getDocumentsByMedicalRecord(
          medicalRecordIdStr,
        );
      } else if (userIdStr != null) {
        // Load documents for all pets owned by this user
        data = await _supabaseService.getDocumentsByOwner(userIdStr);
      } else if (petIdStr != null) {
        // Load documents for a specific pet
        final petData = await _supabaseService.getPetById(petIdStr);
        if (petData != null) {
          final documentsData = await _supabaseService.getDocumentsByPet(
            petIdStr,
          );
          data = documentsData;
        } else {
          data = [];
        }
      } else {
        data = [];
      }

      // Convert String UUID to int for backward compatibility
      _documents = data.map((item) {
        item['id'] = (item['id'] as String).hashCode;
        return Document.fromMap(item);
      }).toList();

      // Filter by access permissions if needed
      if (userId != null && medicalRecordId == null) {
        final userIdInt = userId is int ? userId : userId.hashCode;
        _documents = _documents
            .where((doc) => _canAccessDocument(doc, userIdInt))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      _isLoading = false;
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());
    }
  }

  Future<Document?> uploadDocument({
    required dynamic petId,
    required String fileName,
    File? file,
    List<int>? fileBytes,
    String? description,
    String accessLevel = 'private',
    dynamic? medicalRecordId,
  }) async {
    if (!_authProvider.isLoggedIn) return null;

    _isLoading = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      // Determine file data source
      late int fileSize;
      late List<int> fileData;

      if (file != null) {
        fileSize = file.lengthSync();
        fileData = await file.readAsBytes();
      } else if (fileBytes != null) {
        fileSize = fileBytes.length;
        fileData = fileBytes;
      } else {
        throw Exception('No file data provided');
      }

      // Validate file
      if (fileSize > maxFileSize) {
        throw Exception(
          'File size exceeds maximum limit of ${maxFileSize ~/ (1024 * 1024)}MB',
        );
      }

      final extension = fileName.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw Exception(
          'File type not allowed. Allowed types: ${allowedExtensions.join(", ")}',
        );
      }

      // Generate encryption key
      final encryptionKey = _generateEncryptionKey();

      // Encrypt file data in background isolate for better performance
      final encryptedData = await compute(
        _encryptDataInBackground,
        EncryptData(fileData, encryptionKey),
      );

      // Calculate checksum in background
      final checksum = await compute(_calculateChecksumInBackground, fileData);

      // Save to local storage
      String downloadUrl;
      if (kIsWeb) {
        // For web, store in memory/local storage (simplified approach)
        downloadUrl =
            'web_storage_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await _saveWebFile(downloadUrl, encryptedData);
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        final documentsPath = path.join(documentsDir.path, 'clinic_documents');
        await Directory(documentsPath).create(recursive: true);

        final fileId = DateTime.now().millisecondsSinceEpoch.toString();
        final encryptedFileName = '${fileId}_${fileName}.enc';
        final encryptedFilePath = path.join(documentsPath, encryptedFileName);

        // Save encrypted file locally
        final encryptedFile = File(encryptedFilePath);
        await encryptedFile.writeAsBytes(encryptedData);

        downloadUrl = encryptedFilePath;
      }

      // Get user ID
      final userId = _authProvider.user?.id;
      final userIdStr = _authProvider.user?.id.toString();

      // Create document record
      final documentData = {
        'pet_id': petId.toString(),
        'medical_record_id': medicalRecordId?.toString(),
        'file_name': fileName,
        'file_type': _getFileType(extension),
        'file_path': downloadUrl,
        'description': description,
        'upload_date': DateTime.now().toIso8601String(),
        'version': 1,
        'uploaded_by': userIdStr,
        'access_level': accessLevel,
        'encryption_key': encryptionKey,
        'file_size': fileSize,
        'mime_type': _getMimeType(extension),
        'checksum': checksum,
      };

      final documentId = await _supabaseService.insertDocument(documentData);
      // Convert String UUID to int for backward compatibility
      final documentIdInt = documentId.hashCode;

      final document = Document(
        id: documentIdInt,
        petId: petId is int ? petId : petId.hashCode,
        medicalRecordId: medicalRecordId is int
            ? medicalRecordId
            : medicalRecordId?.hashCode,
        fileName: fileName,
        fileType: _getFileType(extension),
        filePath: downloadUrl,
        description: description,
        uploadDate: DateTime.now(),
        version: 1,
        uploadedBy: userId?.hashCode ?? 0,
        accessLevel: accessLevel,
        encryptionKey: encryptionKey,
        fileSize: fileSize,
        mimeType: _getMimeType(extension),
        checksum: checksum,
      );

      // Add audit log
      await _addAuditLog(documentIdInt, 'upload', 'File uploaded');

      // Send notification to pet owner
      await _notifyOwnerOfUpload(petId.toString(), fileName);

      _documents.add(document);
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());

      return document;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    } finally {
      _isLoading = false;
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());
    }
  }

  Future<bool> downloadDocument(Document document) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      // Check access permissions
      if (!_canAccessDocument(document, _authProvider.user!.id.hashCode)) {
        throw Exception('Access denied');
      }

      // Read from local storage
      List<int> encryptedData;
      if (kIsWeb && document.filePath.startsWith('web_storage_')) {
        // For web, read from SharedPreferences storage
        encryptedData = await _loadWebFile(document.filePath) ?? [];
        if (encryptedData.isEmpty) {
          throw Exception(
            'This document was uploaded before a storage system upgrade and needs to be re-uploaded. Please ask the doctor to re-upload "${document.fileName}".',
          );
        }
      } else {
        final encryptedFile = File(document.filePath);
        if (!await encryptedFile.exists()) {
          throw Exception('File not found: ${document.filePath}');
        }
        encryptedData = await encryptedFile.readAsBytes();
      }

      if (kIsWeb) {
        // For web: decrypt and trigger browser download

        // Decrypt if encrypted
        List<int> finalData = encryptedData;
        if (document.encryptionKey != null) {
          finalData = await compute(
            _decryptDataInBackground,
            EncryptData(encryptedData, document.encryptionKey!),
          );
        }

        // Create blob and trigger download
        final blob = html.Blob([finalData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', document.fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile/desktop: decrypt and save to downloads
        List<int> decryptedData = encryptedData;

        // Decrypt if encrypted
        if (document.encryptionKey != null) {
          decryptedData = await compute(
            _decryptDataInBackground,
            EncryptData(encryptedData, document.encryptionKey!),
          );
        }

        // Save to downloads directory
        final targetDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final targetPath = path.join(targetDir.path, document.fileName);
        final targetFile = File(targetPath);
        await targetFile.writeAsBytes(decryptedData);
      }

      // Add audit log
      if (document.id != null) {
        await _addAuditLog(document.id!, 'download', 'File downloaded');
      }

      return true;
    } catch (e) {
      debugPrint('Error downloading document: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(dynamic documentId) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      final documentIdInt = documentId is int
          ? documentId
          : documentId.hashCode;
      final document = _documents.firstWhere((doc) => doc.id == documentIdInt);

      // Check permissions (only uploader or admin can delete)
      final currentUserIdInt = _authProvider.user!.id.hashCode;
      if (document.uploadedBy != currentUserIdInt &&
          !_authProvider.hasRole('admin')) {
        throw Exception('Permission denied');
      }

      // Delete from local storage
      if (kIsWeb && document.filePath.startsWith('web_storage_')) {
        // For web, remove from SharedPreferences storage
        await _deleteWebFile(document.filePath);
      } else {
        final file = File(document.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete from Supabase database
      final documentIdStr = documentId.toString();
      await _supabaseService.deleteDocument(documentIdStr);

      // Add audit log
      await _addAuditLog(documentIdInt, 'delete', 'File deleted');

      _documents.removeWhere((doc) => doc.id == documentIdInt);
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());

      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  Future<List<AuditLog>> getAuditLogs(dynamic documentId) async {
    try {
      final documentIdStr = documentId.toString();
      final data = await _supabaseService.getAuditLogsByDocument(documentIdStr);
      return data.map((item) {
        item['id'] = (item['id'] as String).hashCode;
        return AuditLog.fromMap(item);
      }).toList();
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
      return [];
    }
  }

  bool _canAccessDocument(Document document, int userId) {
    // Public documents are accessible to all
    if (document.accessLevel == 'public') return true;

    // Private documents only accessible to uploader and pet owner
    if (document.accessLevel == 'private') {
      return document.uploadedBy == userId ||
          _isPetOwner(document.petId, userId);
    }

    // Restricted documents require specific permissions
    return _authProvider.hasRole('admin') || _authProvider.hasRole('doctor');
  }

  bool _isPetOwner(dynamic petId, int userId) {
    // For now, assume owners can access their pets' documents
    // In practice, this should check the database
    return true;
  }

  String _generateEncryptionKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return base64.encode(key.bytes);
  }

  Future<File> _encryptFile(File file, String keyString) async {
    final key = encrypt.Key(base64.decode(keyString));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final fileBytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    final encryptedFile = File('${file.path}.enc');
    await encryptedFile.writeAsBytes(iv.bytes + encrypted.bytes);

    return encryptedFile;
  }

  Future<File> _decryptFile(File file, String keyString) async {
    final key = encrypt.Key(base64.decode(keyString));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final fileBytes = await file.readAsBytes();
    final iv = encrypt.IV(fileBytes.sublist(0, 16));
    final encrypted = encrypt.Encrypted(fileBytes.sublist(16));

    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

    final decryptedFile = File('${file.path}.dec');
    await decryptedFile.writeAsBytes(decrypted);

    return decryptedFile;
  }

  Future<List<int>> _decryptBytes(
    List<int> encryptedData,
    String keyString,
  ) async {
    final key = encrypt.Key(base64.decode(keyString));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    final encrypted = encrypt.Encrypted(
      Uint8List.fromList(encryptedData.sublist(16)),
    );

    return encrypter.decryptBytes(encrypted, iv: iv);
  }

  Future<String> _calculateChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<int>> _encryptBytes(List<int> data, String keyString) async {
    final key = encrypt.Key(base64.decode(keyString));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(data, iv: iv);
    // Return IV + encrypted data
    return iv.bytes + encrypted.bytes;
  }

  Future<String> _calculateChecksumFromBytes(List<int> data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  String _getFileType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image';
      case 'doc':
      case 'docx':
        return 'document';
      case 'txt':
        return 'text';
      default:
        return 'other';
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
        return 'image/jpeg';
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _addAuditLog(
    int documentId,
    String action,
    String details,
  ) async {
    if (!_authProvider.isLoggedIn) return;

    final userIdStr = _authProvider.user?.id.toString();

    await _supabaseService.insertAuditLog({
      'document_id': documentId.toString(),
      'user_id': userIdStr,
      'action': action,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _notifyOwnerOfUpload(String petIdStr, String fileName) async {
    try {
      // Get pet details to find owner
      final pet = await _supabaseService.getPetById(petIdStr);
      if (pet != null) {
        final ownerId = pet['owner_id'];
        if (ownerId != null) {
          // Create notification for the pet owner
          final notificationData = {
            'user_id': ownerId.toString(),
            'title': 'New Medical Document',
            'message':
                'A new document "$fileName" has been uploaded for your pet.',
            'type': 'update',
            'created_at': DateTime.now().toIso8601String(),
            'is_read': false,
            'data': jsonEncode({
              'document_type': 'medical',
              'pet_id': petIdStr,
              'file_name': fileName,
            }),
          };

          await _supabaseService.insertNotification(notificationData);
          debugPrint(
            'Notification sent to owner $ownerId for document "$fileName"',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}

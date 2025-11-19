// lib/providers/document_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../db/db_helper.dart';
import '../models/document.dart';
import '../models/notification.dart' as app_notification;
import '../providers/auth_provider.dart';

class DocumentProvider extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthProvider _authProvider;

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

  Future<void> loadDocuments({int? petId, int? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getDocumentsByPet(petId ?? 0);
      _documents = data.map((item) => Document.fromMap(item)).toList();

      // Filter by access permissions
      if (userId != null) {
        _documents = _documents
            .where((doc) => _canAccessDocument(doc, userId))
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
    required int petId,
    required String fileName,
    required File file,
    String? description,
    String accessLevel = 'private',
  }) async {
    if (!_authProvider.isLoggedIn) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // Validate file
      if (file.lengthSync() > maxFileSize) {
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
      final encryptedFile = await _encryptFile(file, encryptionKey);

      // Calculate checksum
      final checksum = await _calculateChecksum(file);

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child(
        'documents/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      final uploadTask = storageRef.putFile(encryptedFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create document record
      final document = Document(
        petId: petId,
        fileName: fileName,
        fileType: _getFileType(extension),
        filePath: downloadUrl,
        description: description,
        uploadDate: DateTime.now(),
        version: 1,
        uploadedBy: _authProvider.user!.id!,
        accessLevel: accessLevel,
        encryptionKey: encryptionKey,
        fileSize: file.lengthSync(),
        mimeType: _getMimeType(extension),
        checksum: checksum,
      );

      final id = await DBHelper.instance.insertDocument(document.toMap());
      final newDocument = document.copyWith(id: id);

      // Add audit log
      await _addAuditLog(newDocument.id!, 'upload', 'File uploaded');

      // Send notification to pet owner
      await _notifyOwnerOfUpload(petId, fileName);

      _documents.add(newDocument);
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());

      return newDocument;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> downloadDocument(Document document) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      // Check access permissions
      if (!_canAccessDocument(document, _authProvider.user!.id!)) {
        throw Exception('Access denied');
      }

      // Download from Firebase Storage
      final storageRef = _storage.refFromURL(document.filePath);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${document.fileName}');

      await storageRef.writeToFile(tempFile);

      // Decrypt file if encrypted
      File finalFile = tempFile;
      if (document.encryptionKey != null) {
        finalFile = await _decryptFile(tempFile, document.encryptionKey!);
        tempFile.delete(); // Clean up encrypted temp file
      }

      // Save to downloads directory
      final downloadsDir = Directory('/storage/emulated/0/Download'); // Android
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final downloadFile = File('${downloadsDir.path}/${document.fileName}');
      await finalFile.copy(downloadFile.path);

      // Add audit log
      await _addAuditLog(document.id!, 'download', 'File downloaded');

      return true;
    } catch (e) {
      debugPrint('Error downloading document: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(int documentId) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      final document = _documents.firstWhere((doc) => doc.id == documentId);

      // Check permissions (only uploader or admin can delete)
      if (document.uploadedBy != _authProvider.user!.id! &&
          !_authProvider.hasRole('admin')) {
        throw Exception('Permission denied');
      }

      // Delete from Firebase Storage
      final storageRef = _storage.refFromURL(document.filePath);
      await storageRef.delete();

      // Delete from database
      await DBHelper.instance.deleteDocument(documentId);

      // Add audit log
      await _addAuditLog(documentId, 'delete', 'File deleted');

      _documents.removeWhere((doc) => doc.id == documentId);
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());

      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  Future<List<AuditLog>> getAuditLogs(int documentId) async {
    try {
      final data = await DBHelper.instance.getAuditLogsByDocument(documentId);
      return data.map((item) => AuditLog.fromMap(item)).toList();
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

  bool _isPetOwner(int petId, int userId) {
    // This would need to be implemented to check if user owns the pet
    // For now, assume owners can access their pets' documents
    return true; // Placeholder
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

  Future<String> _calculateChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
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

    final auditLog = AuditLog(
      documentId: documentId,
      userId: _authProvider.user!.id!,
      action: action,
      timestamp: DateTime.now(),
      details: details,
    );

    await DBHelper.instance.insertAuditLog(auditLog.toMap());
  }

  Future<void> _notifyOwnerOfUpload(int petId, String fileName) async {
    try {
      // Get pet details to find owner
      final pet = await DBHelper.instance.getPetById(petId);
      if (pet != null) {
        final ownerId = pet['owner_id'];
        if (ownerId != null) {
          // Create notification for the pet owner
          final notification = app_notification.Notification(
            userId: ownerId,
            title: 'New Medical Document',
            message:
                'A new document "$fileName" has been uploaded for your pet.',
            type: 'update',
            createdAt: DateTime.now().toIso8601String(),
            data: {
              'document_type': 'medical',
              'pet_id': petId,
              'file_name': fileName,
            },
          );

          await DBHelper.instance.insertNotification(notification.toMap());
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

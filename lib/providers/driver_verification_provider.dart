// lib/providers/driver_verification_provider.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, compute;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import '../db/db_helper.dart';
import '../models/driver_verification.dart';
import '../providers/auth_provider.dart';

/// Data class for encryption parameters
class DriverEncryptData {
  final List<int> data;
  final String keyString;

  DriverEncryptData(this.data, this.keyString);
}

class DriverVerificationProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  // Web storage using SharedPreferences
  static Future<void> _saveWebFile(String key, List<int> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(data);
    await prefs.setString('driver_verification_$key', encoded);
  }

  static Future<List<int>?> _loadWebFile(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('driver_verification_$key');
    if (encoded != null) {
      return base64Decode(encoded);
    }
    return null;
  }

  static Future<void> _deleteWebFile(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_verification_$key');
  }

  // Top-level function for background encryption
  static Future<List<int>> _encryptDataInBackground(
    DriverEncryptData params,
  ) async {
    final key = encrypt.Key(base64.decode(params.keyString));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(params.data, iv: iv);
    return iv.bytes + encrypted.bytes;
  }

  // Top-level function for background checksum calculation
  static Future<String> _calculateChecksumInBackground(List<int> data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  // Top-level function for background decryption
  static Future<List<int>> _decryptDataInBackground(
    DriverEncryptData params,
  ) async {
    final key = encrypt.Key(base64.decode(params.keyString));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv = encrypt.IV(Uint8List.fromList(params.data.sublist(0, 16)));
    final encrypted = encrypt.Encrypted(
      Uint8List.fromList(params.data.sublist(16)),
    );
    return encrypter.decryptBytes(encrypted, iv: iv);
  }

  List<DriverVerificationDocument> _documents = [];
  DriverVerificationStatus? _verificationStatus;
  bool _isLoading = false;
  String? _error;

  List<DriverVerificationDocument> get documents => _documents;
  DriverVerificationStatus? get verificationStatus => _verificationStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DriverVerificationProvider(this._authProvider);

  // File size limits (in bytes)
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  /// Get the default document requirements for drivers
  static List<DriverDocumentRequirement> getDefaultRequirements() {
    return [
      DriverDocumentRequirement(
        type: 'driving_license',
        title: 'Driving License',
        description:
            'Upload a clear copy of your valid driving license (front and back)',
        required: true,
        helpText:
            'Make sure all text is readable. The license must be valid for at least 30 days from today.',
        vehicleClasses: ['A', 'B', 'C', 'D', 'E'],
      ),
      DriverDocumentRequirement(
        type: 'id_card',
        title: 'National ID Card',
        description: 'Upload a clear copy of your national ID card or passport',
        required: true,
        helpText:
            'Ensure the photo and all text are clearly visible. Expired IDs will not be accepted.',
      ),
      DriverDocumentRequirement(
        type: 'vehicle_insurance',
        title: 'Vehicle Insurance',
        description: 'Upload proof of valid vehicle insurance coverage',
        required: false,
        helpText:
            'The insurance must be valid for the entire period you will be driving.',
      ),
      DriverDocumentRequirement(
        type: 'background_check',
        title: 'Background Check Consent',
        description: 'Upload signed consent form for background verification',
        required: false,
        helpText:
            'Download the consent form from the app, sign it, and upload the signed copy.',
      ),
    ];
  }

  /// Load verification documents for a driver
  Future<void> loadDriverVerificationDocuments(int driverId) async {
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      final data = await DBHelper.instance.getDriverVerificationDocuments(
        driverId,
      );
      _documents = data
          .map((item) => DriverVerificationDocument.fromMap(item))
          .toList();

      // Calculate verification status
      _calculateVerificationStatus(driverId);
    } catch (e) {
      debugPrint('Error loading driver verification documents: $e');
      _error = 'Failed to load verification documents';
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Calculate and update verification status based on documents
  void _calculateVerificationStatus(int driverId) {
    if (_documents.isEmpty) {
      _verificationStatus = DriverVerificationStatus(driverId: driverId);
      return;
    }

    int approved = 0;
    int pending = 0;
    int rejected = 0;
    int expired = 0;
    DateTime? latestLicenseExpiry;

    for (final doc in _documents) {
      switch (doc.status) {
        case 'approved':
          approved++;
          if (doc.documentType == 'driving_license' && doc.expiryDate != null) {
            if (latestLicenseExpiry == null ||
                doc.expiryDate!.isAfter(latestLicenseExpiry)) {
              latestLicenseExpiry = doc.expiryDate;
            }
          }
          break;
        case 'pending':
          pending++;
          break;
        case 'rejected':
          rejected++;
          break;
      }

      // Check for expired documents
      if (doc.isExpired) {
        expired++;
      }
    }

    // Determine overall status
    String overallStatus;
    if (rejected > 0) {
      overallStatus = 'rejected';
    } else if (pending > 0) {
      overallStatus = 'pending';
    } else if (approved > 0) {
      overallStatus = 'approved';
    } else {
      overallStatus = 'partial';
    }

    // Check if driver has a valid driving license
    bool hasValidLicense = _documents.any(
      (doc) =>
          doc.documentType == 'driving_license' &&
          doc.status == 'approved' &&
          !doc.isExpired,
    );

    _verificationStatus = DriverVerificationStatus(
      driverId: driverId,
      overallStatus: overallStatus,
      lastUpdated: DateTime.now(),
      totalDocuments: _documents.length,
      approvedDocuments: approved,
      pendingDocuments: pending,
      rejectedDocuments: rejected,
      expiredDocuments: expired,
      hasValidDrivingLicense: hasValidLicense,
      licenseExpiryDate: latestLicenseExpiry,
    );
  }

  /// Upload a new verification document
  Future<DriverVerificationDocument?> uploadVerificationDocument({
    required int driverId,
    required String documentType,
    required String fileName,
    File? file,
    List<int>? fileBytes,
    String? documentNumber,
    DateTime? expiryDate,
    DateTime? issueDate,
    String? issuingAuthority,
    String? vehicleClass,
  }) async {
    if (!_authProvider.isLoggedIn) return null;

    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      // Determine file data source
      late int fileSize;
      late List<int> fileData;

      if (file != null) {
        fileSize = await file.length();
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

      // Encrypt file data in background isolate
      final encryptedData = await compute(
        _encryptDataInBackground,
        DriverEncryptData(fileData, encryptionKey),
      );

      // Calculate checksum in background
      final checksum = await compute(_calculateChecksumInBackground, fileData);

      // Save to local storage
      String downloadUrl;
      if (kIsWeb) {
        downloadUrl =
            'driver_verification_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await _saveWebFile(downloadUrl, encryptedData);
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        final documentsPath = path.join(
          documentsDir.path,
          'driver_verification_documents',
        );
        await Directory(documentsPath).create(recursive: true);

        final fileId = DateTime.now().millisecondsSinceEpoch.toString();
        final encryptedFileName = '${fileId}_$fileName.enc';
        final encryptedFilePath = path.join(documentsPath, encryptedFileName);

        final encryptedFile = File(encryptedFilePath);
        await encryptedFile.writeAsBytes(encryptedData);

        downloadUrl = encryptedFilePath;
      }

      // Create document record
      final document = DriverVerificationDocument(
        driverId: driverId,
        documentType: documentType,
        fileName: fileName,
        filePath: downloadUrl,
        uploadDate: DateTime.now(),
        status: 'pending',
        documentNumber: documentNumber,
        expiryDate: expiryDate,
        issueDate: issueDate,
        issuingAuthority: issuingAuthority,
        vehicleClass: vehicleClass,
      );

      final id = await DBHelper.instance.insertDriverVerificationDocument(
        document.toMap()
          ..['file_data'] = null
          ..['file_path'] = downloadUrl
          ..['encryption_key'] = encryptionKey,
      );
      final newDocument = document.copyWith(id: id);

      // Add audit log
      await _addAuditLog(newDocument.id!, 'upload', 'Document uploaded');

      _documents.add(newDocument);
      _calculateVerificationStatus(driverId);

      Future.microtask(() => notifyListeners());

      return newDocument;
    } catch (e) {
      debugPrint('Error uploading verification document: $e');
      _error = 'Failed to upload document: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Approve a verification document (for admin use)
  Future<bool> approveDocument(
    int documentId, {
    String? notes,
    int? reviewerId,
  }) async {
    if (!_authProvider.hasRole('admin')) return false;

    try {
      await DBHelper.instance.updateDriverVerificationDocument(documentId, {
        'status': 'approved',
        'review_date': DateTime.now().toIso8601String(),
        'reviewer_id': reviewerId ?? _authProvider.user?.id,
        'review_notes': notes,
      });

      // Update local document
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index >= 0) {
        _documents[index] = _documents[index].copyWith(
          status: 'approved',
          reviewDate: DateTime.now(),
          reviewerId: reviewerId ?? _authProvider.user?.id,
          reviewNotes: notes,
        );
        _calculateVerificationStatus(_documents[index].driverId);
      }

      await _addAuditLog(
        documentId,
        'verify',
        'Document approved${notes != null ? ': $notes' : ''}',
      );

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      debugPrint('Error approving document: $e');
      _error = 'Failed to approve document';
      return false;
    }
  }

  /// Reject a verification document (for admin use)
  Future<bool> rejectDocument(
    int documentId, {
    required String reason,
    int? reviewerId,
  }) async {
    if (!_authProvider.hasRole('admin')) return false;

    try {
      await DBHelper.instance.updateDriverVerificationDocument(documentId, {
        'status': 'rejected',
        'review_date': DateTime.now().toIso8601String(),
        'reviewer_id': reviewerId ?? _authProvider.user?.id,
        'review_notes': reason,
      });

      // Update local document
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index >= 0) {
        _documents[index] = _documents[index].copyWith(
          status: 'rejected',
          reviewDate: DateTime.now(),
          reviewerId: reviewerId ?? _authProvider.user?.id,
          reviewNotes: reason,
        );
        _calculateVerificationStatus(_documents[index].driverId);
      }

      await _addAuditLog(documentId, 'reject', 'Document rejected: $reason');

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      debugPrint('Error rejecting document: $e');
      _error = 'Failed to reject document';
      return false;
    }
  }

  /// Delete a verification document
  Future<bool> deleteVerificationDocument(int documentId) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      final document = _documents.firstWhere((doc) => doc.id == documentId);

      // Delete from local storage
      if (kIsWeb && document.filePath!.startsWith('driver_verification_')) {
        await _deleteWebFile(document.filePath!);
      } else {
        final file = File(document.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete from database
      await DBHelper.instance.deleteDriverVerificationDocument(documentId);

      // Add audit log
      await _addAuditLog(documentId, 'delete', 'Document deleted');

      _documents.removeWhere((doc) => doc.id == documentId);
      _calculateVerificationStatus(document.driverId);

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      debugPrint('Error deleting verification document: $e');
      _error = 'Failed to delete document';
      return false;
    }
  }

  /// Get pending verification documents (for admin)
  Future<List<DriverVerificationDocument>> getPendingDocuments() async {
    try {
      final data = await DBHelper.instance
          .getPendingDriverVerificationDocuments();
      return data
          .map((item) => DriverVerificationDocument.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending documents: $e');
      return [];
    }
  }

  /// Download a verification document
  Future<bool> downloadDocument(DriverVerificationDocument document) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      // Read from local storage
      List<int> encryptedData;
      if (kIsWeb && document.filePath!.startsWith('driver_verification_')) {
        encryptedData = await _loadWebFile(document.filePath!) ?? [];
        if (encryptedData.isEmpty) {
          throw Exception(
            'This document was uploaded before a storage system upgrade and needs to be re-uploaded.',
          );
        }
      } else {
        final encryptedFile = File(document.filePath!);
        if (!await encryptedFile.exists()) {
          throw Exception('File not found: ${document.filePath}');
        }
        encryptedData = await encryptedFile.readAsBytes();
      }

      if (kIsWeb) {
        // For web: decrypt and trigger browser download
        List<int> finalData = encryptedData;
        finalData = await compute(
          _decryptDataInBackground,
          DriverEncryptData(encryptedData, ''),
        );

        final blob = html.Blob([finalData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', document.fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile/desktop: save to downloads
        final targetDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final targetPath = path.join(targetDir.path, document.fileName);
        final targetFile = File(targetPath);
        await targetFile.writeAsBytes(encryptedData);
      }

      await _addAuditLog(document.id!, 'download', 'Document downloaded');

      return true;
    } catch (e) {
      debugPrint('Error downloading document: $e');
      _error = 'Failed to download document';
      return false;
    }
  }

  /// Get audit logs for a document
  Future<List<DriverVerificationAuditLog>> getAuditLogs(int documentId) async {
    try {
      final data = await DBHelper.instance
          .getDriverVerificationAuditLogsByDocument(documentId);
      return data
          .map((item) => DriverVerificationAuditLog.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
      return [];
    }
  }

  /// Generate a unique verification code for a document
  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12).toUpperCase();
  }

  String _generateEncryptionKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return base64.encode(key.bytes);
  }

  Future<void> _addAuditLog(
    int documentId,
    String action,
    String details,
  ) async {
    if (!_authProvider.isLoggedIn) return;

    final auditLog = DriverVerificationAuditLog(
      documentId: documentId,
      userId: _authProvider.user!.id!,
      action: action,
      timestamp: DateTime.now(),
      details: details,
    );

    await DBHelper.instance.insertDriverVerificationAuditLog(auditLog.toMap());
  }

  /// Check if driver has required documents
  bool hasRequiredDocuments() {
    final requirements = getDefaultRequirements();
    final requiredTypes = requirements
        .where((r) => r.required)
        .map((r) => r.type)
        .toList();

    for (final type in requiredTypes) {
      final hasDocument = _documents.any(
        (doc) =>
            doc.documentType == type &&
            (doc.status == 'approved' || doc.status == 'pending'),
      );
      if (!hasDocument) return false;
    }

    return true;
  }

  /// Get documents by type
  List<DriverVerificationDocument> getDocumentsByType(String type) {
    return _documents.where((doc) => doc.documentType == type).toList();
  }

  /// Get the latest document for a specific type
  DriverVerificationDocument? getLatestDocument(String type) {
    final docs = getDocumentsByType(type);
    if (docs.isEmpty) return null;
    docs.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return docs.first;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

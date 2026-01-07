// lib/models/driver_verification.dart

import 'dart:convert';

/// Represents a driving license document for driver verification
class DriverVerificationDocument {
  final int? id;
  final int driverId;
  final String documentType; // 'driving_license', 'id_card', 'other'
  final String fileName;
  final String? filePath;
  final List<int>? fileData; // For web storage
  final DateTime uploadDate;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? reviewDate;
  final int? reviewerId;
  final String? reviewNotes;
  final String? documentNumber; // License number
  final DateTime? expiryDate;
  final DateTime? issueDate; // When the license was issued
  final String? issuingAuthority; // e.g., 'Ministry of Transport'
  final String? vehicleClass; // License class (A, B, C, etc.)
  final String? verificationCode; // For license verification

  DriverVerificationDocument({
    this.id,
    required this.driverId,
    required this.documentType,
    required this.fileName,
    this.filePath,
    this.fileData,
    required this.uploadDate,
    this.status = 'pending',
    this.reviewDate,
    this.reviewerId,
    this.reviewNotes,
    this.documentNumber,
    this.expiryDate,
    this.issueDate,
    this.issuingAuthority,
    this.vehicleClass,
    this.verificationCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'document_type': documentType,
      'file_name': fileName,
      'file_path': filePath,
      'file_data': fileData != null ? base64Encode(fileData!) : null,
      'upload_date': uploadDate.toIso8601String(),
      'status': status,
      'review_date': reviewDate?.toIso8601String(),
      'reviewer_id': reviewerId,
      'review_notes': reviewNotes,
      'document_number': documentNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'issue_date': issueDate?.toIso8601String(),
      'issuing_authority': issuingAuthority,
      'vehicle_class': vehicleClass,
      'verification_code': verificationCode,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DriverVerificationDocument.fromMap(Map<String, dynamic> map) {
    return DriverVerificationDocument(
      id: map['id'],
      driverId: map['driver_id'],
      documentType: map['document_type'],
      fileName: map['file_name'],
      filePath: map['file_path'],
      fileData: map['file_data'] != null
          ? base64Decode(map['file_data'] as String)
          : null,
      uploadDate: DateTime.parse(map['upload_date']),
      status: map['status'] ?? 'pending',
      reviewDate: map['review_date'] != null
          ? DateTime.parse(map['review_date'])
          : null,
      reviewerId: map['reviewer_id'],
      reviewNotes: map['review_notes'],
      documentNumber: map['document_number'],
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      issueDate: map['issue_date'] != null
          ? DateTime.parse(map['issue_date'])
          : null,
      issuingAuthority: map['issuing_authority'],
      vehicleClass: map['vehicle_class'],
      verificationCode: map['verification_code'],
    );
  }

  DriverVerificationDocument copyWith({
    int? id,
    int? driverId,
    String? documentType,
    String? fileName,
    String? filePath,
    List<int>? fileData,
    DateTime? uploadDate,
    String? status,
    DateTime? reviewDate,
    int? reviewerId,
    String? reviewNotes,
    String? documentNumber,
    DateTime? expiryDate,
    DateTime? issueDate,
    String? issuingAuthority,
    String? vehicleClass,
    String? verificationCode,
  }) {
    return DriverVerificationDocument(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileData: fileData ?? this.fileData,
      uploadDate: uploadDate ?? this.uploadDate,
      status: status ?? this.status,
      reviewDate: reviewDate ?? this.reviewDate,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      documentNumber: documentNumber ?? this.documentNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      issueDate: issueDate ?? this.issueDate,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      vehicleClass: vehicleClass ?? this.vehicleClass,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }

  /// Check if the document is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if the document is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return expiryDate!.isBefore(thirtyDaysFromNow) && !isExpired;
  }
}

/// Overall verification status for a driver
class DriverVerificationStatus {
  final int driverId;
  final String
  overallStatus; // 'pending', 'approved', 'rejected', 'partial', 'expired'
  final DateTime? lastUpdated;
  final int totalDocuments;
  final int approvedDocuments;
  final int pendingDocuments;
  final int rejectedDocuments;
  final int expiredDocuments;
  final String? rejectionReason;
  final DateTime? nextReviewDate;
  final bool hasValidDrivingLicense;
  final DateTime? licenseExpiryDate;

  DriverVerificationStatus({
    required this.driverId,
    this.overallStatus = 'pending',
    this.lastUpdated,
    this.totalDocuments = 0,
    this.approvedDocuments = 0,
    this.pendingDocuments = 0,
    this.rejectedDocuments = 0,
    this.expiredDocuments = 0,
    this.rejectionReason,
    this.nextReviewDate,
    this.hasValidDrivingLicense = false,
    this.licenseExpiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'overall_status': overallStatus,
      'last_updated': lastUpdated?.toIso8601String(),
      'total_documents': totalDocuments,
      'approved_documents': approvedDocuments,
      'pending_documents': pendingDocuments,
      'rejected_documents': rejectedDocuments,
      'expired_documents': expiredDocuments,
      'rejection_reason': rejectionReason,
      'next_review_date': nextReviewDate?.toIso8601String(),
      'has_valid_driving_license': hasValidDrivingLicense ? 1 : 0,
      'license_expiry_date': licenseExpiryDate?.toIso8601String(),
    };
  }

  factory DriverVerificationStatus.fromMap(Map<String, dynamic> map) {
    return DriverVerificationStatus(
      driverId: map['driver_id'],
      overallStatus: map['overall_status'] ?? 'pending',
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
      totalDocuments: map['total_documents'] ?? 0,
      approvedDocuments: map['approved_documents'] ?? 0,
      pendingDocuments: map['pending_documents'] ?? 0,
      rejectedDocuments: map['rejected_documents'] ?? 0,
      expiredDocuments: map['expired_documents'] ?? 0,
      rejectionReason: map['rejection_reason'],
      nextReviewDate: map['next_review_date'] != null
          ? DateTime.parse(map['next_review_date'])
          : null,
      hasValidDrivingLicense: map['has_valid_driving_license'] == 1,
      licenseExpiryDate: map['license_expiry_date'] != null
          ? DateTime.parse(map['license_expiry_date'])
          : null,
    );
  }

  DriverVerificationStatus copyWith({
    int? driverId,
    String? overallStatus,
    DateTime? lastUpdated,
    int? totalDocuments,
    int? approvedDocuments,
    int? pendingDocuments,
    int? rejectedDocuments,
    int? expiredDocuments,
    String? rejectionReason,
    DateTime? nextReviewDate,
    bool? hasValidDrivingLicense,
    DateTime? licenseExpiryDate,
  }) {
    return DriverVerificationStatus(
      driverId: driverId ?? this.driverId,
      overallStatus: overallStatus ?? this.overallStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      approvedDocuments: approvedDocuments ?? this.approvedDocuments,
      pendingDocuments: pendingDocuments ?? this.pendingDocuments,
      rejectedDocuments: rejectedDocuments ?? this.rejectedDocuments,
      expiredDocuments: expiredDocuments ?? this.expiredDocuments,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      hasValidDrivingLicense:
          hasValidDrivingLicense ?? this.hasValidDrivingLicense,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
    );
  }

  /// Check if the driver is approved to drive
  bool get canDrive {
    return overallStatus == 'approved' && hasValidDrivingLicense;
  }
}

/// Requirement for driver verification documents
class DriverDocumentRequirement {
  final String type;
  final String title;
  final String description;
  final bool required;
  final String? helpText;
  final List<String> allowedExtensions;
  final int? maxFileSize; // in bytes
  final List<String>? vehicleClasses; // For driving license

  DriverDocumentRequirement({
    required this.type,
    required this.title,
    required this.description,
    this.required = true,
    this.helpText,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.maxFileSize = 5 * 1024 * 1024, // 5MB default
    this.vehicleClasses,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'required': required ? 1 : 0,
      'help_text': helpText,
      'allowed_extensions': jsonEncode(allowedExtensions),
      'max_file_size': maxFileSize,
      'vehicle_classes': vehicleClasses != null
          ? jsonEncode(vehicleClasses)
          : null,
    };
  }

  factory DriverDocumentRequirement.fromMap(Map<String, dynamic> map) {
    return DriverDocumentRequirement(
      type: map['type'],
      title: map['title'],
      description: map['description'],
      required: map['required'] == 1,
      helpText: map['help_text'],
      allowedExtensions: jsonDecode(map['allowed_extensions'] ?? '[]'),
      maxFileSize: map['max_file_size'],
      vehicleClasses: map['vehicle_classes'] != null
          ? jsonDecode(map['vehicle_classes'] as String).cast<String>()
          : null,
    );
  }
}

/// Audit log for driver verification documents
class DriverVerificationAuditLog {
  final int? id;
  final int documentId;
  final int userId;
  final String
  action; // 'upload', 'download', 'view', 'delete', 'update', 'verify', 'reject'
  final DateTime timestamp;
  final String? details;
  final String? ipAddress;

  DriverVerificationAuditLog({
    this.id,
    required this.documentId,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.details,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'ip_address': ipAddress,
    };
  }

  factory DriverVerificationAuditLog.fromMap(Map<String, dynamic> map) {
    return DriverVerificationAuditLog(
      id: map['id'],
      documentId: map['document_id'],
      userId: map['user_id'],
      action: map['action'],
      timestamp: DateTime.parse(map['timestamp']),
      details: map['details'],
      ipAddress: map['ip_address'],
    );
  }
}

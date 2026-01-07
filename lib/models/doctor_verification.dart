// lib/models/doctor_verification.dart

import 'dart:convert';

class DoctorVerificationDocument {
  final int? id;
  final int doctorId;
  final String documentType;
  final String fileName;
  final String? filePath;
  final List<int>? fileData; // For web storage
  final DateTime uploadDate;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? reviewDate;
  final int? reviewerId;
  final String? reviewNotes;
  final String? documentNumber; // License number, diploma number, etc.
  final DateTime? expiryDate;
  final String? issuingAuthority;
  final String? verificationCode; // For license verification

  DoctorVerificationDocument({
    this.id,
    required this.doctorId,
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
    this.issuingAuthority,
    this.verificationCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_id': doctorId,
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
      'issuing_authority': issuingAuthority,
      'verification_code': verificationCode,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DoctorVerificationDocument.fromMap(Map<String, dynamic> map) {
    return DoctorVerificationDocument(
      id: map['id'],
      doctorId: map['doctor_id'],
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
      issuingAuthority: map['issuing_authority'],
      verificationCode: map['verification_code'],
    );
  }

  DoctorVerificationDocument copyWith({
    int? id,
    int? doctorId,
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
    String? issuingAuthority,
    String? verificationCode,
  }) {
    return DoctorVerificationDocument(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
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
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }
}

class DoctorVerificationStatus {
  final int doctorId;
  final String overallStatus; // 'pending', 'approved', 'rejected', 'partial'
  final DateTime? lastUpdated;
  final int totalDocuments;
  final int approvedDocuments;
  final int pendingDocuments;
  final int rejectedDocuments;
  final String? rejectionReason;
  final DateTime? nextReviewDate;

  DoctorVerificationStatus({
    required this.doctorId,
    this.overallStatus = 'pending',
    this.lastUpdated,
    this.totalDocuments = 0,
    this.approvedDocuments = 0,
    this.pendingDocuments = 0,
    this.rejectedDocuments = 0,
    this.rejectionReason,
    this.nextReviewDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctor_id': doctorId,
      'overall_status': overallStatus,
      'last_updated': lastUpdated?.toIso8601String(),
      'total_documents': totalDocuments,
      'approved_documents': approvedDocuments,
      'pending_documents': pendingDocuments,
      'rejected_documents': rejectedDocuments,
      'rejection_reason': rejectionReason,
      'next_review_date': nextReviewDate?.toIso8601String(),
    };
  }

  factory DoctorVerificationStatus.fromMap(Map<String, dynamic> map) {
    return DoctorVerificationStatus(
      doctorId: map['doctor_id'],
      overallStatus: map['overall_status'] ?? 'pending',
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
      totalDocuments: map['total_documents'] ?? 0,
      approvedDocuments: map['approved_documents'] ?? 0,
      pendingDocuments: map['pending_documents'] ?? 0,
      rejectedDocuments: map['rejected_documents'] ?? 0,
      rejectionReason: map['rejection_reason'],
      nextReviewDate: map['next_review_date'] != null
          ? DateTime.parse(map['next_review_date'])
          : null,
    );
  }

  DoctorVerificationStatus copyWith({
    int? doctorId,
    String? overallStatus,
    DateTime? lastUpdated,
    int? totalDocuments,
    int? approvedDocuments,
    int? pendingDocuments,
    int? rejectedDocuments,
    String? rejectionReason,
    DateTime? nextReviewDate,
  }) {
    return DoctorVerificationStatus(
      doctorId: doctorId ?? this.doctorId,
      overallStatus: overallStatus ?? this.overallStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      approvedDocuments: approvedDocuments ?? this.approvedDocuments,
      pendingDocuments: pendingDocuments ?? this.pendingDocuments,
      rejectedDocuments: rejectedDocuments ?? this.rejectedDocuments,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    );
  }
}

class DocumentRequirement {
  final String type;
  final String title;
  final String description;
  final bool required;
  final String? helpText;
  final List<String> allowedExtensions;
  final int? maxFileSize; // in bytes

  DocumentRequirement({
    required this.type,
    required this.title,
    required this.description,
    this.required = true,
    this.helpText,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.maxFileSize = 5 * 1024 * 1024, // 5MB default
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
    };
  }

  factory DocumentRequirement.fromMap(Map<String, dynamic> map) {
    return DocumentRequirement(
      type: map['type'],
      title: map['title'],
      description: map['description'],
      required: map['required'] == 1,
      helpText: map['help_text'],
      allowedExtensions: jsonDecode(map['allowed_extensions'] ?? '[]'),
      maxFileSize: map['max_file_size'],
    );
  }
}

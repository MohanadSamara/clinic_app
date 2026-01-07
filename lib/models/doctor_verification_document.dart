import 'dart:convert';

class DoctorVerificationDocument {
  final int? id;
  final int doctorId; // Links to user table
  final String
  documentType; // 'license', 'certificate', 'diploma', 'id_card', 'other'
  final String fileName;
  final String fileType; // 'image', 'pdf', 'document'
  final String filePath;
  final String? description;
  final DateTime uploadDate;
  final int version;
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final int? verifiedBy; // Admin user ID
  final int fileSize;
  final String? mimeType;
  final String? checksum;
  final List<AuditLog>? auditLogs;

  DoctorVerificationDocument({
    this.id,
    required this.doctorId,
    required this.documentType,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    this.description,
    required this.uploadDate,
    this.version = 1,
    this.verificationStatus = 'pending',
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    required this.fileSize,
    this.mimeType,
    this.checksum,
    this.auditLogs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'document_type': documentType,
      'file_name': fileName,
      'file_type': fileType,
      'file_path': filePath,
      'description': description,
      'upload_date': uploadDate.toIso8601String(),
      'version': version,
      'verification_status': verificationStatus,
      'rejection_reason': rejectionReason,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'file_size': fileSize,
      'mime_type': mimeType,
      'checksum': checksum,
      'audit_logs': auditLogs != null
          ? jsonEncode(auditLogs!.map((log) => log.toMap()).toList())
          : null,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DoctorVerificationDocument.fromMap(Map<String, dynamic> map) {
    return DoctorVerificationDocument(
      id: map['id'],
      doctorId: map['doctor_id'],
      documentType: map['document_type'],
      fileName: map['file_name'],
      fileType: map['file_type'],
      filePath: map['file_path'],
      description: map['description'],
      uploadDate: DateTime.parse(map['upload_date']),
      version: map['version'] ?? 1,
      verificationStatus: map['verification_status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      verifiedAt: map['verified_at'] != null
          ? DateTime.parse(map['verified_at'])
          : null,
      verifiedBy: map['verified_by'],
      fileSize: map['file_size'] ?? 0,
      mimeType: map['mime_type'],
      checksum: map['checksum'],
      auditLogs: map['audit_logs'] != null
          ? (jsonDecode(map['audit_logs'] as String) as List)
                .map((log) => AuditLog.fromMap(log as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  DoctorVerificationDocument copyWith({
    int? id,
    int? doctorId,
    String? documentType,
    String? fileName,
    String? fileType,
    String? filePath,
    String? description,
    DateTime? uploadDate,
    int? version,
    String? verificationStatus,
    String? rejectionReason,
    DateTime? verifiedAt,
    int? verifiedBy,
    int? fileSize,
    String? mimeType,
    String? checksum,
    List<AuditLog>? auditLogs,
  }) {
    return DoctorVerificationDocument(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      uploadDate: uploadDate ?? this.uploadDate,
      version: version ?? this.version,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      checksum: checksum ?? this.checksum,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

class AuditLog {
  final int? id;
  final int documentId;
  final int userId;
  final String
  action; // 'upload', 'download', 'view', 'delete', 'update', 'verify', 'reject'
  final DateTime timestamp;
  final String? details;
  final String? ipAddress;

  AuditLog({
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

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
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

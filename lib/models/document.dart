class Document {
  final int? id;
  final int petId;
  final int? medicalRecordId; // Link to medical record
  final String fileName;
  final String fileType; // 'image', 'pdf', 'document'
  final String filePath;
  final String? description;
  final DateTime uploadDate;
  final int version;
  final int uploadedBy;
  final String accessLevel; // 'public', 'private', 'restricted'
  final String? encryptionKey;
  final int fileSize;
  final String? mimeType;
  final String? checksum;
  final List<AuditLog>? auditLogs;

  Document({
    this.id,
    required this.petId,
    this.medicalRecordId,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    this.description,
    required this.uploadDate,
    this.version = 1,
    required this.uploadedBy,
    this.accessLevel = 'private',
    this.encryptionKey,
    required this.fileSize,
    this.mimeType,
    this.checksum,
    this.auditLogs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pet_id': petId,
      'medical_record_id': medicalRecordId,
      'file_name': fileName,
      'file_type': fileType,
      'file_path': filePath,
      'description': description,
      'upload_date': uploadDate.toIso8601String(),
      'version': version,
      'uploaded_by': uploadedBy,
      'access_level': accessLevel,
      'encryption_key': encryptionKey,
      'file_size': fileSize,
      'mime_type': mimeType,
      'checksum': checksum,
      'audit_logs': auditLogs?.map((log) => log.toMap()).toList(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      petId: map['pet_id'],
      medicalRecordId: map['medical_record_id'],
      fileName: map['file_name'],
      fileType: map['file_type'],
      filePath: map['file_path'],
      description: map['description'],
      uploadDate: DateTime.parse(map['upload_date']),
      version: map['version'] ?? 1,
      uploadedBy: map['uploaded_by'],
      accessLevel: map['access_level'] ?? 'private',
      encryptionKey: map['encryption_key'],
      fileSize: map['file_size'] ?? 0,
      mimeType: map['mime_type'],
      checksum: map['checksum'],
      auditLogs: map['audit_logs'] != null
          ? (map['audit_logs'] as List)
                .map((log) => AuditLog.fromMap(log))
                .toList()
          : null,
    );
  }

  Document copyWith({
    int? id,
    int? petId,
    int? medicalRecordId,
    String? fileName,
    String? fileType,
    String? filePath,
    String? description,
    DateTime? uploadDate,
    int? version,
    int? uploadedBy,
    String? accessLevel,
    String? encryptionKey,
    int? fileSize,
    String? mimeType,
    String? checksum,
    List<AuditLog>? auditLogs,
  }) {
    return Document(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      medicalRecordId: medicalRecordId ?? this.medicalRecordId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      uploadDate: uploadDate ?? this.uploadDate,
      version: version ?? this.version,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      accessLevel: accessLevel ?? this.accessLevel,
      encryptionKey: encryptionKey ?? this.encryptionKey,
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
  final String action; // 'upload', 'download', 'view', 'delete', 'update'
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

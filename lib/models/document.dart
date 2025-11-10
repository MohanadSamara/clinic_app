class Document {
  final int? id;
  final int petId;
  final String fileName;
  final String fileType; // 'image', 'pdf', 'document'
  final String filePath;
  final String? description;
  final DateTime uploadDate;

  Document({
    this.id,
    required this.petId,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    this.description,
    required this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pet_id': petId,
      'file_name': fileName,
      'file_type': fileType,
      'file_path': filePath,
      'description': description,
      'upload_date': uploadDate.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      petId: map['pet_id'],
      fileName: map['file_name'],
      fileType: map['file_type'],
      filePath: map['file_path'],
      description: map['description'],
      uploadDate: DateTime.parse(map['upload_date']),
    );
  }

  Document copyWith({
    int? id,
    int? petId,
    String? fileName,
    String? fileType,
    String? filePath,
    String? description,
    DateTime? uploadDate,
  }) {
    return Document(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }
}

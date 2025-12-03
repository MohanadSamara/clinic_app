// lib/models/medical_record.dart
class MedicalRecord {
  final int? id;
  final int petId;
  final int doctorId;
  final String diagnosis;
  final String treatment;
  final String? prescription;
  final String? notes;
  final String date;
  final List<String>? attachments; // file paths

  MedicalRecord({
    this.id,
    required this.petId,
    required this.doctorId,
    required this.diagnosis,
    required this.treatment,
    this.prescription,
    this.notes,
    required this.date,
    this.attachments,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'pet_id': petId,
    'doctor_id': doctorId,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'prescription': prescription,
    'notes': notes,
    'date': date,
    'attachments': attachments?.join(','),
  };

  factory MedicalRecord.fromMap(Map<String, dynamic> m) => MedicalRecord(
    id: m['id'] is int ? m['id'] as int : null,
    petId: m['pet_id'] is int ? m['pet_id'] as int : 0,
    doctorId: m['doctor_id'] is int ? m['doctor_id'] as int : 0,
    diagnosis: m['diagnosis']?.toString() ?? '',
    treatment: m['treatment']?.toString() ?? '',
    prescription: m['prescription']?.toString(),
    notes: m['notes']?.toString(),
    date: m['date']?.toString() ?? '',
    attachments: m['attachments']?.toString().split(','),
  );

  MedicalRecord copyWith({
    int? id,
    int? petId,
    int? doctorId,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    String? date,
    List<String>? attachments,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      doctorId: doctorId ?? this.doctorId,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MedicalRecord) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}

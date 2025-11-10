class VaccinationRecord {
  final int? id;
  final int petId;
  final String vaccineName;
  final DateTime vaccinationDate;
  final DateTime? nextDueDate;
  final String? batchNumber;
  final String? veterinarianName;
  final String? notes;

  VaccinationRecord({
    this.id,
    required this.petId,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDueDate,
    this.batchNumber,
    this.veterinarianName,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pet_id': petId,
      'vaccine_name': vaccineName,
      'vaccination_date': vaccinationDate.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'batch_number': batchNumber,
      'veterinarian_name': veterinarianName,
      'notes': notes,
    };
  }

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      id: map['id'],
      petId: map['pet_id'],
      vaccineName: map['vaccine_name'],
      vaccinationDate: DateTime.parse(map['vaccination_date']),
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'])
          : null,
      batchNumber: map['batch_number'],
      veterinarianName: map['veterinarian_name'],
      notes: map['notes'],
    );
  }

  VaccinationRecord copyWith({
    int? id,
    int? petId,
    String? vaccineName,
    DateTime? vaccinationDate,
    DateTime? nextDueDate,
    String? batchNumber,
    String? veterinarianName,
    String? notes,
  }) {
    return VaccinationRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccinationDate: vaccinationDate ?? this.vaccinationDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      batchNumber: batchNumber ?? this.batchNumber,
      veterinarianName: veterinarianName ?? this.veterinarianName,
      notes: notes ?? this.notes,
    );
  }
}

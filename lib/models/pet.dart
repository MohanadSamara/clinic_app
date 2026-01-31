// lib/models/pet.dart
// Pet Model - Original structure preserved
// Firestore integration handled by provider layer

import 'dart:convert';

class Pet {
  final int? id;
  final int ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? dob;
  final String? notes;
  final String? medicalHistorySummary;
  final Map<String, dynamic>? vaccinationStatus;
  final String? photoPath;
  final String serialNumber;

  Pet({
    this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.dob,
    this.notes,
    this.medicalHistorySummary,
    this.vaccinationStatus,
    this.photoPath,
    required this.serialNumber,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'owner_id': ownerId,
    'name': name,
    'species': species,
    'breed': breed,
    'dob': dob,
    'notes': notes,
    'medical_history_summary': medicalHistorySummary,
    'vaccination_status': vaccinationStatus != null
        ? jsonEncode(vaccinationStatus)
        : null,
    'photo_path': photoPath,
    'serial_number': serialNumber,
  };

  Map<String, dynamic> toJson() => toMap();

  factory Pet.fromMap(Map<String, dynamic> m) => Pet(
    id: m['id'],
    ownerId: m['owner_id'] is int ? m['owner_id'] as int : 0,
    name: m['name'] ?? '',
    species: m['species'] ?? '',
    breed: m['breed'],
    dob: m['dob'],
    notes: m['notes'],
    medicalHistorySummary: m['medical_history_summary'],
    vaccinationStatus: m['vaccination_status'] != null
        ? jsonDecode(m['vaccination_status'].toString())
        : null,
    photoPath: m['photo_path'],
    serialNumber: m['serial_number'] ?? '',
  );

  int? get ageInYears {
    if (dob == null) return null;
    try {
      final birthDate = DateTime.parse(dob!);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  String get ageDisplay {
    final age = ageInYears;
    if (age == null) return 'Age unknown';
    if (age == 0) return 'Less than 1 year';
    if (age == 1) return '1 year old';
    return '$age years old';
  }

  Pet copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? species,
    String? breed,
    String? dob,
    String? notes,
    String? medicalHistorySummary,
    Map<String, dynamic>? vaccinationStatus,
    String? photoPath,
    String? serialNumber,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      dob: dob ?? this.dob,
      notes: notes ?? this.notes,
      medicalHistorySummary:
          medicalHistorySummary ?? this.medicalHistorySummary,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      photoPath: photoPath ?? this.photoPath,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  static String generateSerialNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'PET-${timestamp.toString().substring(8)}-${random.toString().padLeft(4, '0')}';
  }

  factory Pet.create({
    required int ownerId,
    required String name,
    required String species,
    String? breed,
    String? dob,
    String? notes,
    String? medicalHistorySummary,
    Map<String, dynamic>? vaccinationStatus,
    String? photoPath,
  }) {
    return Pet(
      ownerId: ownerId,
      name: name,
      species: species,
      breed: breed,
      dob: dob,
      notes: notes,
      medicalHistorySummary: medicalHistorySummary,
      vaccinationStatus: vaccinationStatus,
      photoPath: photoPath,
      serialNumber: generateSerialNumber(),
    );
  }
}

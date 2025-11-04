// lib/models/pet.dart
import 'dart:convert';

// lib/models/pet.dart
class Pet {
  final int? id;
  final int ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? dob;
  final String? notes;
  final String? medicalHistorySummary;
  final Map<String, dynamic>? vaccinationStatus; // JSON object
  final String? photoPath;

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
  };

  factory Pet.fromMap(Map<String, dynamic> m) => Pet(
    id: m['id'],
    ownerId: m['owner_id'],
    name: m['name'] ?? '',
    species: m['species'] ?? '',
    breed: m['breed'],
    dob: m['dob'],
    notes: m['notes'],
    medicalHistorySummary: m['medical_history_summary'],
    vaccinationStatus: m['vaccination_status'] != null
        ? jsonDecode(m['vaccination_status'])
        : null,
    photoPath: m['photo_path'],
  );

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
    );
  }
}

// lib/models/generic_data_model.dart
// Generic data model for any user-generated data in Firestore

import 'package:flutter/foundation.dart';

/// Generic data model for user-generated data
/// Stored at: users/{uid}/data/{autoId}
class GenericDataModel {
  final String? id;
  final String
  collectionName; // e.g., 'pets', 'appointments', 'medical_records'
  final String userId; // Owner of the data (matches auth.uid)
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  GenericDataModel({
    this.id,
    required this.collectionName,
    required this.userId,
    required this.data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create from Firestore document
  factory GenericDataModel.fromMap(
    String docId,
    String collectionName,
    Map<String, dynamic> data,
  ) {
    return GenericDataModel(
      id: docId,
      collectionName: collectionName,
      userId: data['userId'] ?? '',
      data: data['data'] ?? {},
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'collectionName': collectionName,
      'userId': userId,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with changes
  GenericDataModel copyWith({
    String? id,
    String? collectionName,
    String? userId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GenericDataModel(
      id: id ?? this.id,
      collectionName: collectionName ?? this.collectionName,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Update data and timestamp
  GenericDataModel updateData(Map<String, dynamic> newData) {
    return copyWith(data: newData, updatedAt: DateTime.now());
  }
}

/// Specific data types for the clinic app
class PetModel {
  final String? id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final DateTime? dob;
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetModel({
    this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.dob,
    this.notes,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create from Firestore document
  factory PetModel.fromMap(String docId, Map<String, dynamic> data) {
    return PetModel(
      id: docId,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      breed: data['breed'],
      dob: data['dob'] != null ? DateTime.parse(data['dob']) : null,
      notes: data['notes'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'dob': dob?.toIso8601String(),
      'notes': notes,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with changes
  PetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? breed,
    DateTime? dob,
    String? notes,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      dob: dob ?? this.dob,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class AppointmentModel extends GenericDataModel {
  final String petId;
  final String serviceType;
  final DateTime scheduledAt;
  final String status;
  final String? description;
  final String? address;
  final double? price;
  final String? doctorId;
  final String? driverId;

  AppointmentModel({
    String? id,
    required String userId,
    required this.petId,
    required this.serviceType,
    required this.scheduledAt,
    this.status = 'pending',
    this.description,
    this.address,
    this.price,
    this.doctorId,
    this.driverId,
  }) : super(
         id: id,
         collectionName: 'appointments',
         userId: userId,
         data: {
           'petId': petId,
           'serviceType': serviceType,
           'scheduledAt': scheduledAt.toIso8601String(),
           'status': status,
           'description': description,
           'address': address,
           'price': price,
           'doctorId': doctorId,
           'driverId': driverId,
         },
       );

  factory AppointmentModel.fromGeneric(GenericDataModel model) {
    return AppointmentModel(
      id: model.id,
      userId: model.userId,
      petId: model.data['petId'] ?? '',
      serviceType: model.data['serviceType'] ?? '',
      scheduledAt: model.data['scheduledAt'] != null
          ? DateTime.parse(model.data['scheduledAt'])
          : DateTime.now(),
      status: model.data['status'] ?? 'pending',
      description: model.data['description'],
      address: model.data['address'],
      price: model.data['price']?.toDouble(),
      doctorId: model.data['doctorId'],
      driverId: model.data['driverId'],
    );
  }
}

class MedicalRecordModel extends GenericDataModel {
  final String petId;
  final String diagnosis;
  final String? treatment;
  final String? prescription;
  final String? notes;
  final DateTime date;

  MedicalRecordModel({
    String? id,
    required String userId,
    required this.petId,
    required this.diagnosis,
    this.treatment,
    this.prescription,
    this.notes,
    required this.date,
  }) : super(
         id: id,
         collectionName: 'medical_records',
         userId: userId,
         data: {
           'petId': petId,
           'diagnosis': diagnosis,
           'treatment': treatment,
           'prescription': prescription,
           'notes': notes,
           'date': date.toIso8601String(),
         },
       );

  factory MedicalRecordModel.fromGeneric(GenericDataModel model) {
    return MedicalRecordModel(
      id: model.id,
      userId: model.userId,
      petId: model.data['petId'] ?? '',
      diagnosis: model.data['diagnosis'] ?? '',
      treatment: model.data['treatment'],
      prescription: model.data['prescription'],
      notes: model.data['notes'],
      date: model.data['date'] != null
          ? DateTime.parse(model.data['date'])
          : DateTime.now(),
    );
  }
}

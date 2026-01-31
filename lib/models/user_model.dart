// lib/models/user_model.dart
// User model for Firebase Firestore

import 'package:flutter/foundation.dart';

enum UserRole { owner, doctor, driver, admin }

class UserModel {
  final String? id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? area;
  final String? profileImage;
  final String verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? linkedDoctorId;
  final String? linkedDriverId;
  final String? availabilityStatus;

  UserModel({
    this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.area,
    this.profileImage,
    this.verificationStatus = 'verified',
    this.createdAt,
    this.updatedAt,
    this.linkedDoctorId,
    this.linkedDriverId,
    this.availabilityStatus,
  });

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> data, String docId) {
    return UserModel(
      id: docId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      role: _parseRole(data['role']),
      area: data['area'],
      profileImage: data['profileImage'],
      verificationStatus: data['verificationStatus'] ?? 'verified',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : null,
      linkedDoctorId: data['linkedDoctorId'],
      linkedDriverId: data['linkedDriverId'],
      availabilityStatus: data['availabilityStatus'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'area': area,
      'profileImage': profileImage,
      'verificationStatus': verificationStatus,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'linkedDoctorId': linkedDoctorId,
      'linkedDriverId': linkedDriverId,
      'availabilityStatus': availabilityStatus,
    };
  }

  // Copy with changes
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? area,
    String? profileImage,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedDoctorId,
    String? linkedDriverId,
    String? availabilityStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      area: area ?? this.area,
      profileImage: profileImage ?? this.profileImage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedDoctorId: linkedDoctorId ?? this.linkedDoctorId,
      linkedDriverId: linkedDriverId ?? this.linkedDriverId,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      case 'owner':
      default:
        return UserRole.owner;
    }
  }
}

// lib/models/user.dart
import 'dart:convert';

class User {
  final int? id;
  final String name;
  final String email;
  final String password; // Will be hashed in production
  final String? phone;
  final String role;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.role = 'owner',
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'role': role,
  };

  factory User.fromMap(Map<String, dynamic> m) => User(
    id: m['id'],
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    password: m['password'] ?? '',
    phone: m['phone'],
    role: m['role'] ?? 'owner',
  );

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}

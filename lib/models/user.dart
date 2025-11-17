// lib/models/user.dart

class User {
  final int? id;
  final String name;
  final String email;
  final String password; // Will be hashed in production
  final String? phone;
  final String role;
  final String? provider; // e.g., 'google', 'facebook', 'email'
  final String? providerId; // ID from social provider

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.role = 'owner',
    this.provider,
    this.providerId,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'role': role,
    'provider': provider,
    'providerId': providerId,
  };

  factory User.fromMap(Map<String, dynamic> m) => User(
    id: m['id'],
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    password: m['password'] ?? '',
    phone: m['phone'],
    role: m['role'] ?? 'owner',
    provider: m['provider'],
    providerId: m['providerId'],
  );

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? role,
    String? provider,
    String? providerId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
    );
  }
}

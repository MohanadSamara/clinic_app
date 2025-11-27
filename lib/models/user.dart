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
  final String? profileImage; // Path to profile image
  final int? linkedDoctorId; // For drivers: which doctor they work with
  final int? linkedDriverId; // For doctors: which driver works with them

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.role = 'owner',
    this.provider,
    this.providerId,
    this.profileImage,
    this.linkedDoctorId,
    this.linkedDriverId,
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
    'profileImage': profileImage,
    'linked_doctor_id': linkedDoctorId,
    'linked_driver_id': linkedDriverId,
  };

  factory User.fromMap(Map<String, dynamic> m) => User(
    id: m['id'] is int ? m['id'] as int : null,
    name: m['name']?.toString() ?? 'Unknown',
    email: m['email']?.toString() ?? 'No email',
    password: m['password']?.toString() ?? '',
    phone: m['phone']?.toString(),
    role: m['role']?.toString() ?? 'owner',
    provider: m['provider']?.toString(),
    providerId: m['providerId']?.toString(),
    profileImage: m['profileImage']?.toString(),
    linkedDoctorId: m['linked_doctor_id'] is int
        ? m['linked_doctor_id'] as int
        : null,
    linkedDriverId: m['linked_driver_id'] is int
        ? m['linked_driver_id'] as int
        : null,
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
    String? profileImage,
    int? linkedDoctorId,
    int? linkedDriverId,
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
      profileImage: profileImage ?? this.profileImage,
      linkedDoctorId: linkedDoctorId ?? this.linkedDoctorId,
      linkedDriverId: linkedDriverId ?? this.linkedDriverId,
    );
  }
}

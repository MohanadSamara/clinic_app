// lib/models/user.dart

class User {
  final String? id;
  final String name;
  final String email;
  final String password; // Will be hashed in production
  final String? phone;
  final String role;
  final String? provider; // e.g., 'google', 'facebook', 'email'
  final String? providerId; // ID from social provider
  final String? profileImage; // Path to profile image
  final String? area; // Preferred area for doctors and drivers
  final String? linkedDoctorId; // For drivers: which doctor they work with
  final String? linkedDriverId; // For doctors: which driver works with them
  final String availabilityStatus; // 'online', 'offline', 'busy', 'away'
  final String? lastSeen; // ISO timestamp
  final String
  verificationStatus; // 'verified', 'pending', 'rejected', 'partial' - for doctors

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
    this.area,
    this.linkedDoctorId,
    this.linkedDriverId,
    this.availabilityStatus = 'offline',
    this.lastSeen,
    this.verificationStatus = 'verified', // Default to verified for non-doctors
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'role': role,
    'provider': provider,
    'provider_id': providerId,
    'profile_image': profileImage,
    'area': area,
    'linked_doctor_id': linkedDoctorId,
    'linked_driver_id': linkedDriverId,
    'availability_status': availabilityStatus,
    'last_seen': lastSeen,
    'verification_status': verificationStatus,
  };

  Map<String, dynamic> toJson() => toMap();

  factory User.fromMap(Map<String, dynamic> m) => User(
    id: m['id']?.toString(),
    name: _validateName(m['name']?.toString()),
    email: m['email']?.toString() ?? 'No email',
    password: m['password']?.toString() ?? '',
    phone: m['phone']?.toString(),
    role: m['role']?.toString() ?? 'owner',
    provider: m['provider']?.toString(),
    providerId: m['provider_id']?.toString(),
    profileImage: m['profile_image']?.toString(),
    area: m['area']?.toString(),
    linkedDoctorId: m['linked_doctor_id']?.toString(),
    linkedDriverId: m['linked_driver_id']?.toString(),
    availabilityStatus: m['availability_status']?.toString() ?? 'offline',
    lastSeen: m['last_seen']?.toString(),
    verificationStatus: m['verification_status']?.toString() ?? 'verified',
  );

  static String _validateName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    // Check if it looks like a closure toString
    if (name.startsWith('Closure:') || name.contains('=>')) return 'Unknown';
    return name;
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? role,
    String? provider,
    String? providerId,
    String? profileImage,
    String? area,
    String? linkedDoctorId,
    String? linkedDriverId,
    String? availabilityStatus,
    String? lastSeen,
    String? verificationStatus,
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
      area: area ?? this.area,
      linkedDoctorId: linkedDoctorId ?? this.linkedDoctorId,
      linkedDriverId: linkedDriverId ?? this.linkedDriverId,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

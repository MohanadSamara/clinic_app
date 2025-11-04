// lib/models/user.dart

class User {
  final int? id;
  final String name;
  final String email;
  final String password; // plain text in demo (not secure)
  final String? phone;
  final String role;
  final Map<String, dynamic>? permissions; // role-based permissions

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.role = 'owner',
    this.permissions,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'role': role,
    // 'permissions': permissions != null ? jsonEncode(permissions) : null, // Commented out for now
  };

  factory User.fromMap(Map<String, dynamic> m) => User(
    id: m['id'],
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    password: m['password'] ?? '',
    phone: m['phone'],
    role: m['role'] ?? 'owner',
    // permissions: m['permissions'] != null ? jsonDecode(m['permissions']) : null, // Commented out for now
  );
}

import 'package:uuid/uuid.dart';

/// Van model - UUID-only for database operations
/// NEVER use id/hashCode for Supabase operations
class Van {
  final String? id; // Database UUID - can be null for new vans
  final String name;
  final String licensePlate;
  final String? model;
  final int capacity;
  final String status;
  final String? description;
  final String? area;
  final String? assignedDriverId;
  final String? assignedDoctorId;
  final String? createdAt;

  Van({
    this.id,
    required this.name,
    required this.licensePlate,
    this.model,
    this.capacity = 1,
    this.status = 'available',
    this.description,
    this.area,
    this.assignedDriverId,
    this.assignedDoctorId,
    this.createdAt,
  });

  /// Create from Supabase data - id must be a valid UUID
  factory Van.fromSupabase(Map<String, dynamic> map) {
    final idStr = map['id']?.toString() ?? '';
    if (idStr.isEmpty || !_isValidUUID(idStr)) {
      throw ArgumentError('Invalid UUID from database: $idStr');
    }
    return Van(
      id: idStr,
      name: map['name'] ?? '',
      licensePlate: map['license_plate'] ?? '',
      model: map['model'],
      capacity: map['capacity'] ?? 1,
      status: map['status'] ?? 'available',
      description: map['description'],
      area: map['area'],
      assignedDriverId: map['assigned_driver_id']?.toString(),
      assignedDoctorId: map['assigned_doctor_id']?.toString(),
      createdAt: map['created_at'],
    );
  }

  /// Backward compatibility factory
  factory Van.fromMap(Map<String, dynamic> map) => Van.fromSupabase(map);

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'name': name,
    'license_plate': licensePlate,
    'model': model,
    'capacity': capacity,
    'status': status,
    'description': description,
    'area': area,
    'assigned_driver_id': assignedDriverId,
    'assigned_doctor_id': assignedDoctorId,
    'created_at': createdAt,
  };

  Van copyWith({
    String? id,
    String? name,
    String? licensePlate,
    String? model,
    int? capacity,
    String? status,
    String? description,
    String? area,
    String? assignedDriverId,
    String? assignedDoctorId,
    String? createdAt,
  }) => Van(
    id: id ?? this.id,
    name: name ?? this.name,
    licensePlate: licensePlate ?? this.licensePlate,
    model: model ?? this.model,
    capacity: capacity ?? this.capacity,
    status: status ?? this.status,
    description: description ?? this.description,
    area: area ?? this.area,
    assignedDriverId: assignedDriverId ?? this.assignedDriverId,
    assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
    createdAt: createdAt ?? this.createdAt,
  );

  bool get isAvailable => status == 'available';
  bool get isAssigned =>
      status == 'assigned' &&
      assignedDriverId != null &&
      assignedDoctorId != null;
  bool get isPartiallyAssigned =>
      status == 'assigned' &&
      ((assignedDriverId != null && assignedDoctorId == null) ||
          (assignedDriverId == null && assignedDoctorId != null));
  bool get isFullyAssigned =>
      assignedDriverId != null && assignedDoctorId != null;

  Map<String, dynamic> toJson() => toSupabase();

  /// Alias for toSupabase for backward compatibility
  Map<String, dynamic> toMap() => toSupabase();

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static bool _isValidUUID(String uuid) =>
      uuid.isNotEmpty && _uuidRegex.hasMatch(uuid);
}

/// Example of WRONG usage:
/// ```dart
/// final van = Van(...);
/// provider.assignVanToDoctorAndDriver(vanId: van.id!, ...); // ❌ WRONG - van.id is hashCode
/// ```
///
/// Example of CORRECT usage:
/// ```dart
/// final van = Van(...);
/// provider.assignVanToDoctorAndDriver(vanId: van.id!, ...); // ✅ CORRECT - van.id is UUID string (nullable)

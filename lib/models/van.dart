class Van {
  final int? id;
  final String name;
  final String licensePlate;
  final String? model;
  final int capacity;
  final String
  status; // 'available', 'assigned', 'maintenance', 'out_of_service'
  final String? description;
  final String? area;
  final int? assignedDriverId;
  final int? assignedDoctorId;
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

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory Van.fromMap(Map<String, dynamic> map) {
    return Van(
      id: map['id'],
      name: map['name'] ?? '',
      licensePlate: map['license_plate'] ?? '',
      model: map['model'],
      capacity: map['capacity'] ?? 1,
      status: map['status'] ?? 'available',
      description: map['description'],
      area: map['area'],
      assignedDriverId: map['assigned_driver_id'],
      assignedDoctorId: map['assigned_doctor_id'],
      createdAt: map['created_at'],
    );
  }

  Van copyWith({
    int? id,
    String? name,
    String? licensePlate,
    String? model,
    int? capacity,
    String? status,
    String? description,
    String? area,
    int? assignedDriverId,
    int? assignedDoctorId,
    String? createdAt,
  }) {
    return Van(
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
  }

  bool get isAvailable => status == 'available';
  bool get isAssigned =>
      status == 'assigned' &&
      assignedDriverId != null &&
      assignedDoctorId != null;
  bool get isPartiallyAssigned =>
      status == 'assigned' &&
      ((assignedDriverId != null && assignedDoctorId == null) ||
          (assignedDriverId == null && assignedDoctorId != null));
  bool get isInMaintenance => status == 'maintenance';
  bool get isOutOfService => status == 'out_of_service';
  bool get isFullyAssigned =>
      assignedDriverId != null && assignedDoctorId != null;
}

// lib/models/van.dart
class Van {
  final int? id;
  final String type; // e.g., 'consultation', 'surgery', 'emergency'
  final String licensePlate;
  final int driverId; // Each van is operated by one driver
  final bool isActive;

  Van({
    this.id,
    required this.type,
    required this.licensePlate,
    required this.driverId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type,
    'license_plate': licensePlate,
    'driver_id': driverId,
    'is_active': isActive ? 1 : 0,
  };

  factory Van.fromMap(Map<String, dynamic> m) => Van(
    id: m['id'],
    type: m['type'] ?? '',
    licensePlate: m['license_plate'] ?? '',
    driverId: m['driver_id'],
    isActive: m['is_active'] == 1,
  );

  Van copyWith({
    int? id,
    String? type,
    String? licensePlate,
    int? driverId,
    bool? isActive,
  }) {
    return Van(
      id: id ?? this.id,
      type: type ?? this.type,
      licensePlate: licensePlate ?? this.licensePlate,
      driverId: driverId ?? this.driverId,
      isActive: isActive ?? this.isActive,
    );
  }
}

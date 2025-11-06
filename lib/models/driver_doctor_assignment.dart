// lib/models/driver_doctor_assignment.dart
class DriverDoctorAssignment {
  final int? id;
  final int driverId;
  final int doctorId; // Each doctor has their own dedicated driver
  final bool isActive;

  DriverDoctorAssignment({
    this.id,
    required this.driverId,
    required this.doctorId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'driver_id': driverId,
    'doctor_id': doctorId,
    'is_active': isActive ? 1 : 0,
  };

  factory DriverDoctorAssignment.fromMap(Map<String, dynamic> m) =>
      DriverDoctorAssignment(
        id: m['id'],
        driverId: m['driver_id'],
        doctorId: m['doctor_id'],
        isActive: m['is_active'] == 1,
      );

  DriverDoctorAssignment copyWith({
    int? id,
    int? driverId,
    int? doctorId,
    bool? isActive,
  }) {
    return DriverDoctorAssignment(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      doctorId: doctorId ?? this.doctorId,
      isActive: isActive ?? this.isActive,
    );
  }
}

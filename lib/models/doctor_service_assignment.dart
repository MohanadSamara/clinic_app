// lib/models/doctor_service_assignment.dart
class DoctorServiceAssignment {
  final int? id;
  final int doctorId;
  final int serviceId; // Each doctor is assigned to exactly one service
  final bool isActive;

  DoctorServiceAssignment({
    this.id,
    required this.doctorId,
    required this.serviceId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'doctor_id': doctorId,
    'service_id': serviceId,
    'is_active': isActive ? 1 : 0,
  };

  factory DoctorServiceAssignment.fromMap(Map<String, dynamic> m) =>
      DoctorServiceAssignment(
        id: m['id'],
        doctorId: m['doctor_id'],
        serviceId: m['service_id'],
        isActive: m['is_active'] == 1,
      );

  DoctorServiceAssignment copyWith({
    int? id,
    int? doctorId,
    int? serviceId,
    bool? isActive,
  }) {
    return DoctorServiceAssignment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      serviceId: serviceId ?? this.serviceId,
      isActive: isActive ?? this.isActive,
    );
  }
}

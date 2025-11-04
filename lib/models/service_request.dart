class ServiceRequest {
  final int? id;
  final int ownerId;
  final int petId;
  final String requestType; // 'urgent', 'checkup'
  final String description;
  final String
  status; // 'pending', 'approved', 'assigned', 'in_progress', 'completed', 'rejected'
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime requestDate;
  final DateTime? scheduledDate;
  final int? assignedDoctorId;
  final int? assignedDriverId;
  final String? rejectionReason;

  ServiceRequest({
    this.id,
    required this.ownerId,
    required this.petId,
    required this.requestType,
    required this.description,
    this.status = 'pending',
    this.latitude,
    this.longitude,
    this.address,
    required this.requestDate,
    this.scheduledDate,
    this.assignedDoctorId,
    this.assignedDriverId,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'pet_id': petId,
      'request_type': requestType,
      'description': description,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'request_date': requestDate.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'assigned_doctor_id': assignedDoctorId,
      'assigned_driver_id': assignedDriverId,
      'rejection_reason': rejectionReason,
    };
  }

  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    return ServiceRequest(
      id: map['id'],
      ownerId: map['owner_id'],
      petId: map['pet_id'],
      requestType: map['request_type'],
      description: map['description'],
      status: map['status'] ?? 'pending',
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      requestDate: DateTime.parse(map['request_date']),
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.parse(map['scheduled_date'])
          : null,
      assignedDoctorId: map['assigned_doctor_id'],
      assignedDriverId: map['assigned_driver_id'],
      rejectionReason: map['rejection_reason'],
    );
  }

  ServiceRequest copyWith({
    int? id,
    int? ownerId,
    int? petId,
    String? requestType,
    String? description,
    String? status,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? requestDate,
    DateTime? scheduledDate,
    int? assignedDoctorId,
    int? assignedDriverId,
    String? rejectionReason,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      petId: petId ?? this.petId,
      requestType: requestType ?? this.requestType,
      description: description ?? this.description,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      requestDate: requestDate ?? this.requestDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

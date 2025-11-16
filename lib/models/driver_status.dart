class DriverStatus {
  final int? id;
  final int driverId;
  final double latitude;
  final double longitude;
  final String status; // 'available', 'busy', 'on_route', 'arrived', 'offline'
  final int? currentAppointmentId;
  final String lastUpdated;

  DriverStatus({
    this.id,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.currentAppointmentId,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'current_appointment_id': currentAppointmentId,
      'last_updated': lastUpdated,
    };
  }

  factory DriverStatus.fromMap(Map<String, dynamic> map) {
    return DriverStatus(
      id: map['id'],
      driverId: map['driver_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
      currentAppointmentId: map['current_appointment_id'],
      lastUpdated: map['last_updated'],
    );
  }

  DriverStatus copyWith({
    int? id,
    int? driverId,
    double? latitude,
    double? longitude,
    String? status,
    int? currentAppointmentId,
    String? lastUpdated,
  }) {
    return DriverStatus(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      currentAppointmentId: currentAppointmentId ?? this.currentAppointmentId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// lib/models/driver_status.dart
class DriverStatus {
  final int? id;
  final int driverId;
  final double latitude;
  final double longitude;
  final String status; // 'available', 'on_route', 'busy', 'offline'
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

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'driver_id': driverId,
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'current_appointment_id': currentAppointmentId,
    'last_updated': lastUpdated,
  };

  factory DriverStatus.fromMap(Map<String, dynamic> m) => DriverStatus(
    id: m['id'],
    driverId: m['driver_id'],
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    status: m['status'] ?? 'offline',
    currentAppointmentId: m['current_appointment_id'],
    lastUpdated: m['last_updated'] ?? '',
  );
}

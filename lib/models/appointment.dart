// lib/models/appointment.dart
class Appointment {
  final int? id;
  final int ownerId;
  final int petId;
  final String serviceType;
  final String? description;
  final String scheduledAt;
  final String status;
  final String? address;
  final double? price;
  final int? driverId;
  final int? doctorId;
  final String urgencyLevel; // 'routine', 'urgent', 'emergency'
  final double? locationLat;
  final double? locationLng;

  Appointment({
    this.id,
    required this.ownerId,
    required this.petId,
    required this.serviceType,
    this.description,
    required this.scheduledAt,
    this.status = 'pending',
    this.address,
    this.price,
    this.driverId,
    this.doctorId,
    this.urgencyLevel = 'routine',
    this.locationLat,
    this.locationLng,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'owner_id': ownerId,
    'pet_id': petId,
    'service_type': serviceType,
    'description': description,
    'scheduled_at': scheduledAt,
    'status': status,
    'address': address,
    'price': price,
    'driver_id': driverId,
    'doctor_id': doctorId,
    'urgency_level': urgencyLevel,
    'location_lat': locationLat,
    'location_lng': locationLng,
  };

  factory Appointment.fromMap(Map<String, dynamic> m) => Appointment(
    id: m['id'],
    ownerId: m['owner_id'],
    petId: m['pet_id'],
    serviceType: m['service_type'] ?? '',
    description: m['description'],
    scheduledAt: m['scheduled_at'] ?? '',
    status: m['status'] ?? 'pending',
    address: m['address'],
    price: (m['price'] is int)
        ? (m['price'] as int).toDouble()
        : (m['price'] as double?),
    driverId: m['driver_id'],
    doctorId: m['doctor_id'],
    urgencyLevel: m['urgency_level'] ?? 'routine',
    locationLat: (m['location_lat'] as num?)?.toDouble(),
    locationLng: (m['location_lng'] as num?)?.toDouble(),
  );

  Appointment copyWith({
    int? id,
    int? ownerId,
    int? petId,
    String? serviceType,
    String? description,
    String? scheduledAt,
    String? status,
    String? address,
    double? price,
    int? driverId,
    int? doctorId,
    String? urgencyLevel,
    double? locationLat,
    double? locationLng,
  }) {
    return Appointment(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      petId: petId ?? this.petId,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      address: address ?? this.address,
      price: price ?? this.price,
      driverId: driverId ?? this.driverId,
      doctorId: doctorId ?? this.doctorId,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
    );
  }
}

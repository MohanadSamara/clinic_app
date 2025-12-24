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
  final int? doctorId;
  final String? doctorName;
  final int? driverId;
  final String? driverName;
  final String urgencyLevel; // 'routine', 'urgent', 'emergency'
  final double? locationLat;
  final double? locationLng;
  final String? calendarEventId;
  final String? paymentMethod; // 'online', 'cash'
  final int? serviceRequestId;

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
    this.doctorId,
    this.doctorName,
    this.driverId,
    this.driverName,
    this.urgencyLevel = 'routine',
    this.locationLat,
    this.locationLng,
    this.calendarEventId,
    this.paymentMethod,
    this.serviceRequestId,
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
    'doctor_id': doctorId,
    'driver_id': driverId,
    'urgency_level': urgencyLevel,
    'location_lat': locationLat,
    'location_lng': locationLng,
    'calendar_event_id': calendarEventId,
    'payment_method': paymentMethod,
    'service_request_id': serviceRequestId,
  };

  factory Appointment.fromMap(Map<String, dynamic> m) => Appointment(
    id: m['id'] is int ? m['id'] as int : null,
    ownerId: m['owner_id'] is int ? m['owner_id'] as int : 0,
    petId: m['pet_id'] is int ? m['pet_id'] as int : 0,
    serviceType: m['service_type']?.toString() ?? '',
    description: m['description']?.toString(),
    scheduledAt: m['scheduled_at']?.toString() ?? '',
    status: m['status']?.toString() ?? 'pending',
    address: m['address']?.toString(),
    price: m['price'] is num ? (m['price'] as num).toDouble() : null,
    doctorId: m['doctor_id'] is int ? m['doctor_id'] as int : null,
    doctorName: m['doctor_name']?.toString(),
    driverId: m['driver_id'] is int ? m['driver_id'] as int : null,
    driverName: m['driver_name']?.toString(),
    urgencyLevel: m['urgency_level']?.toString() ?? 'routine',
    locationLat: m['location_lat'] is num
        ? (m['location_lat'] as num).toDouble()
        : null,
    locationLng: m['location_lng'] is num
        ? (m['location_lng'] as num).toDouble()
        : null,
    calendarEventId: m['calendar_event_id']?.toString(),
    paymentMethod: m['payment_method']?.toString(),
    serviceRequestId: m['service_request_id'] is int
        ? m['service_request_id'] as int
        : null,
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
    int? doctorId,
    String? doctorName,
    int? driverId,
    String? driverName,
    String? urgencyLevel,
    double? locationLat,
    double? locationLng,
    String? calendarEventId,
    String? paymentMethod,
    int? serviceRequestId,
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
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
    );
  }
}








class Route {
  final int? id;
  final int driverId;
  final DateTime date;
  final List<int> appointmentIds; // Ordered list of appointment IDs
  final String status; // 'planned', 'in_progress', 'completed'
  final double? totalDistance; // in kilometers
  final int? estimatedDuration; // in minutes
  final DateTime? startTime;
  final DateTime? endTime;

  Route({
    this.id,
    required this.driverId,
    required this.date,
    required this.appointmentIds,
    this.status = 'planned',
    this.totalDistance,
    this.estimatedDuration,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'date': date.toIso8601String(),
      'appointment_ids': appointmentIds.join(','),
      'status': status,
      'total_distance': totalDistance,
      'estimated_duration': estimatedDuration,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'],
      driverId: map['driver_id'],
      date: DateTime.parse(map['date']),
      appointmentIds: (map['appointment_ids'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList(),
      status: map['status'] ?? 'planned',
      totalDistance: map['total_distance'],
      estimatedDuration: map['estimated_duration'],
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'])
          : null,
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
    );
  }

  Route copyWith({
    int? id,
    int? driverId,
    DateTime? date,
    List<int>? appointmentIds,
    String? status,
    double? totalDistance,
    int? estimatedDuration,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Route(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      date: date ?? this.date,
      appointmentIds: appointmentIds ?? this.appointmentIds,
      status: status ?? this.status,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

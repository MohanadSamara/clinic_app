class DoctorSchedule {
  final String? id; // Firestore document ID (String)
  final String doctorId; // Firebase Auth UID (String)
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final String startTime; // '09:00'
  final String endTime; // '17:00'
  final bool isActive;
  final bool isHoliday; // Whether this day is a holiday (no work)
  final bool isFreeDay; // Whether this day has custom working hours

  DoctorSchedule({
    this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.isHoliday = false,
    this.isFreeDay = false,
  });

  // For local DB (int)
  Map<String, dynamic> toMapForLocal() {
    return {
      'id': id != null ? int.tryParse(id!) : null,
      'doctor_id': int.tryParse(doctorId),
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive ? 1 : 0,
      'is_holiday': isHoliday ? 1 : 0,
      'is_free_day': isFreeDay ? 1 : 0,
    };
  }

  // For Firestore (String)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive ? 1 : 0,
      'isHoliday': isHoliday ? 1 : 0,
      'isFreeDay': isFreeDay ? 1 : 0,
    };
  }

  factory DoctorSchedule.fromMap(Map<String, dynamic> map) {
    // Check if it's Firestore format (camelCase) or local DB format (snake_case)
    final isFirestore = map.containsKey('doctorId');

    return DoctorSchedule(
      id: map['id']?.toString(),
      doctorId: isFirestore
          ? map['doctorId']?.toString() ?? ''
          : map['doctor_id']?.toString() ?? '',
      dayOfWeek: map[isFirestore ? 'dayOfWeek' : 'day_of_week'] ?? '',
      startTime: map[isFirestore ? 'startTime' : 'start_time'] ?? '08:00',
      endTime: map[isFirestore ? 'endTime' : 'end_time'] ?? '18:00',
      isActive:
          map[isFirestore ? 'isActive' : 'is_active'] == 1 ||
          map[isFirestore ? 'isActive' : 'is_active'] == true,
      isHoliday:
          map[isFirestore ? 'isHoliday' : 'is_holiday'] == 1 ||
          map[isFirestore ? 'isHoliday' : 'is_holiday'] == true,
      isFreeDay:
          map[isFirestore ? 'isFreeDay' : 'is_free_day'] == 1 ||
          map[isFirestore ? 'isFreeDay' : 'is_free_day'] == true,
    );
  }

  DoctorSchedule copyWith({
    String? id,
    String? doctorId,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
    bool? isHoliday,
    bool? isFreeDay,
  }) {
    return DoctorSchedule(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      isHoliday: isHoliday ?? this.isHoliday,
      isFreeDay: isFreeDay ?? this.isFreeDay,
    );
  }
}

class DoctorSchedule {
  final int? id;
  final int doctorId;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive ? 1 : 0,
      'is_holiday': isHoliday ? 1 : 0,
      'is_free_day': isFreeDay ? 1 : 0,
    };
  }

  factory DoctorSchedule.fromMap(Map<String, dynamic> map) {
    return DoctorSchedule(
      id: map['id'],
      doctorId: map['doctor_id'],
      dayOfWeek: map['day_of_week'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      isActive: map['is_active'] == 1,
      isHoliday: map['is_holiday'] == 1,
      isFreeDay: map['is_free_day'] == 1,
    );
  }

  DoctorSchedule copyWith({
    int? id,
    int? doctorId,
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

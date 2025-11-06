// lib/models/service_session.dart
class ServiceSession {
  final int? id;
  final int userId; // doctor or driver id
  final String userRole; // 'doctor' or 'driver'
  final int selectedServiceId; // service they want to work on for this session
  final String sessionDate; // date of the session
  final bool isActive;

  ServiceSession({
    this.id,
    required this.userId,
    required this.userRole,
    required this.selectedServiceId,
    required this.sessionDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'user_role': userRole,
    'selected_service_id': selectedServiceId,
    'session_date': sessionDate,
    'is_active': isActive ? 1 : 0,
  };

  factory ServiceSession.fromMap(Map<String, dynamic> m) => ServiceSession(
    id: m['id'],
    userId: m['user_id'],
    userRole: m['user_role'] ?? '',
    selectedServiceId: m['selected_service_id'],
    sessionDate: m['session_date'] ?? '',
    isActive: m['is_active'] == 1,
  );

  ServiceSession copyWith({
    int? id,
    int? userId,
    String? userRole,
    int? selectedServiceId,
    String? sessionDate,
    bool? isActive,
  }) {
    return ServiceSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      selectedServiceId: selectedServiceId ?? this.selectedServiceId,
      sessionDate: sessionDate ?? this.sessionDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

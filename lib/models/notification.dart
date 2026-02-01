import 'dart:convert';

class Notification {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final Map<String, dynamic>? data;

  Notification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    String? createdAt,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt,
      'data': data != null ? jsonEncode(data) : null,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      data: map['data'] != null
          ? (map['data'] is String
              ? jsonDecode(map['data'] as String)
              : map['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Notification) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}

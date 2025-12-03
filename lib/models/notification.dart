import 'dart:convert';

class Notification {
  final int? id;
  final int userId;
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
      'id': id,
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
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      createdAt: map['created_at'],
      data: map['data'] != null ? jsonDecode(map['data'] as String) : null,
    );
  }
}

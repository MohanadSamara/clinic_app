// lib/models/notification.dart
import 'dart:convert';

class Notification {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final String type; // 'reminder', 'alert', 'update'
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic>? data; // additional data for actions

  Notification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'title': title,
    'message': message,
    'type': type,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt,
    'data': data != null ? jsonEncode(data) : null,
  };

  factory Notification.fromMap(Map<String, dynamic> m) => Notification(
    id: m['id'],
    userId: m['user_id'],
    title: m['title'] ?? '',
    message: m['message'] ?? '',
    type: m['type'] ?? '',
    isRead: m['is_read'] == 1,
    createdAt: m['created_at'] ?? '',
    data: m['data'] != null ? jsonDecode(m['data']) : null,
  );

  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    String? createdAt,
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

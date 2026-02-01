import 'package:flutter/material.dart';

enum NotificationType {
  vaccination,
  checkup,
  followup,
  clinicArrival,
  appointment,
  urgentCase,
  general,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime scheduledTime;
  final String? relatedId; // appointment id, pet id, etc.
  final bool isScheduled;
  final bool isDelivered;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String? userId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
    this.relatedId,
    this.isScheduled = false,
    this.isDelivered = false,
    this.isRead = false,
    DateTime? createdAt,
    this.data,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'scheduled_at': scheduledTime.toIso8601String(),
      'related_id': relatedId,
      'is_scheduled': isScheduled,
      'is_delivered': isDelivered,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      scheduledTime: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'])
          : (map['scheduledTime'] != null 
              ? DateTime.parse(map['scheduledTime'])
              : DateTime.now()),
      relatedId: map['related_id']?.toString() ?? map['relatedId']?.toString(),
      isScheduled: map['is_scheduled'] == true || map['is_scheduled'] == 1 || map['isScheduled'] == true || map['isScheduled'] == 1,
      isDelivered: map['is_delivered'] == true || map['is_delivered'] == 1 || map['isDelivered'] == true || map['isDelivered'] == 1,
      isRead: map['is_read'] == true || map['is_read'] == 1 || map['isRead'] == true || map['isRead'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : (map['createdAt'] != null 
              ? DateTime.parse(map['createdAt'])
              : DateTime.now()),
      data: map['data'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? scheduledTime,
    String? relatedId,
    bool? isScheduled,
    bool? isDelivered,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      relatedId: relatedId ?? this.relatedId,
      isScheduled: isScheduled ?? this.isScheduled,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

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
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
    this.relatedId,
    this.isScheduled = false,
    this.isDelivered = false,
    DateTime? createdAt,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'relatedId': relatedId,
      'isScheduled': isScheduled ? 1 : 0,
      'isDelivered': isDelivered ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      scheduledTime: DateTime.parse(map['scheduledTime']),
      relatedId: map['relatedId'],
      isScheduled: map['isScheduled'] == 1,
      isDelivered: map['isDelivered'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      data: map['data'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? scheduledTime,
    String? relatedId,
    bool? isScheduled,
    bool? isDelivered,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      relatedId: relatedId ?? this.relatedId,
      isScheduled: isScheduled ?? this.isScheduled,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}








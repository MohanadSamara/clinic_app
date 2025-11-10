// lib/providers/notification_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/appointment.dart';
import '../models/vaccination_record.dart';
import '../models/notification.dart' as app;

class NotificationProvider extends ChangeNotifier {
  List<app.Notification> _notifications = [];
  bool _isLoading = false;

  List<app.Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> loadNotificationsForUser(int userId, {bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DBHelper.instance.getNotificationsByUser(
        userId,
        unreadOnly: unreadOnly,
      );
      _notifications = data.map((item) => app.Notification.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await DBHelper.instance.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> syncOwnerReminders({
    required int ownerId,
    List<Appointment> appointments = const [],
    List<VaccinationRecord> vaccinations = const [],
  }) async {
    await loadNotificationsForUser(ownerId);
    await _ensureAppointmentReminders(ownerId, appointments);
    await _ensureVaccinationReminders(ownerId, vaccinations);
    await loadNotificationsForUser(ownerId);
  }

  Future<void> _ensureAppointmentReminders(
    int ownerId,
    List<Appointment> appointments,
  ) async {
    final now = DateTime.now();
    for (final appointment in appointments) {
      if (appointment.id == null) continue;
      final key = 'apt-${appointment.id}-reminder';
      final alreadyExists = _notifications.any(
        (n) => n.data != null && n.data!['key'] == key,
      );
      if (alreadyExists) continue;

      final scheduled = DateTime.tryParse(appointment.scheduledAt)?.toLocal();
      if (scheduled == null) continue;
      final diff = scheduled.difference(now);

      if (diff.inHours <= 24 && !diff.isNegative &&
          _pendingStatuses.contains(appointment.status)) {
        await _createReminder(
          ownerId: ownerId,
          title: 'Upcoming appointment',
          message:
              '${appointment.serviceType} for pet #${appointment.petId} is scheduled ${_formatDateTime(scheduled)}.',
          key: key,
          data: {
            'appointment_id': appointment.id,
            'status': appointment.status,
          },
        );
        _notifications.add(
          app.Notification(
            id: null,
            userId: ownerId,
            title: 'Upcoming appointment',
            message:
                '${appointment.serviceType} for pet #${appointment.petId} is scheduled ${_formatDateTime(scheduled)}.',
            type: 'reminder',
            isRead: false,
            createdAt: DateTime.now().toIso8601String(),
            data: {'key': key},
          ),
        );
      } else if (appointment.status == 'completed') {
        final followUpKey = 'apt-${appointment.id}-followup';
        final followUpExists = _notifications.any(
          (n) => n.data != null && n.data!['key'] == followUpKey,
        );
        if (followUpExists) continue;
        final followUpDate = scheduled.add(const Duration(days: 7));
        if (now.isAfter(scheduled) && now.isBefore(followUpDate)) {
          await _createReminder(
            ownerId: ownerId,
            title: 'Post-visit follow-up',
            message:
                'How is your pet doing after the ${appointment.serviceType}? Consider booking a follow-up if needed.',
            key: followUpKey,
            data: {'appointment_id': appointment.id},
          );
          _notifications.add(
            app.Notification(
              id: null,
              userId: ownerId,
              title: 'Post-visit follow-up',
              message:
                  'How is your pet doing after the ${appointment.serviceType}? Consider booking a follow-up if needed.',
              type: 'reminder',
              isRead: false,
              createdAt: DateTime.now().toIso8601String(),
              data: {'key': followUpKey},
            ),
          );
        }
      }
    }
  }

  Future<void> _ensureVaccinationReminders(
    int ownerId,
    List<VaccinationRecord> vaccinations,
  ) async {
    final now = DateTime.now();
    for (final record in vaccinations) {
      if (record.id == null || record.nextDueDate == null) continue;
      final key = 'vac-${record.id}-reminder';
      final exists = _notifications.any(
        (n) => n.data != null && n.data!['key'] == key,
      );
      if (exists) continue;

      final diff = record.nextDueDate!.difference(now);
      if (diff.inDays <= 7 && !diff.isNegative) {
        await _createReminder(
          ownerId: ownerId,
          title: 'Vaccination due soon',
          message:
              '${record.vaccineName} booster is due on ${_formatDate(record.nextDueDate!)}.',
          key: key,
          data: {
            'vaccine': record.vaccineName,
            'pet_id': record.petId,
          },
        );
        _notifications.add(
          app.Notification(
            id: null,
            userId: ownerId,
            title: 'Vaccination due soon',
            message:
                '${record.vaccineName} booster is due on ${_formatDate(record.nextDueDate!)}.',
            type: 'reminder',
            isRead: false,
            createdAt: DateTime.now().toIso8601String(),
            data: {'key': key},
          ),
        );
      }
    }
  }

  Future<void> _createReminder({
    required int ownerId,
    required String title,
    required String message,
    required String key,
    Map<String, dynamic>? data,
  }) async {
    try {
      await DBHelper.instance.insertNotification({
        'user_id': ownerId,
        'title': title,
        'message': message,
        'type': 'reminder',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
        'data': jsonEncode({
          'key': key,
          if (data != null) ...data,
        }),
      });
    } catch (e) {
      debugPrint('Error creating reminder: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final date = '${_padZero(local.day)}/${_padZero(local.month)}';
    final time = '${_padZero(local.hour)}:${_padZero(local.minute)}';
    return 'on $date at $time';
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${_padZero(local.day)}/${_padZero(local.month)}/${local.year}';
  }

  String _padZero(int value) => value.toString().padLeft(2, '0');
}

const Set<String> _pendingStatuses = {
  'pending',
  'confirmed',
  'rescheduled',
};

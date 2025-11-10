// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/notification.dart' as app_notification;
import '../models/appointment.dart';
import '../models/vaccination_record.dart';
import '../models/service_request.dart';

class NotificationProvider extends ChangeNotifier {
  final List<app_notification.Notification> _notifications = [];
  final List<app_notification.Notification> _reminders = [];
  bool _isLoading = false;

  final DateFormat _dateFormatter = DateFormat('MMM d, y');
  final DateFormat _timeFormatter = DateFormat('jm');

  bool get isLoading => _isLoading;

  List<app_notification.Notification> get notifications => [
        ..._notifications,
        ..._reminders,
      ]
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

  Future<void> loadNotifications(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DBHelper.instance.getNotificationsByUser(userId);
      _notifications
        ..clear()
        ..addAll(
          data.map((item) => app_notification.Notification.fromMap(item)),
        );
    } catch (e) {
      debugPrint('Error loading notifications: $e');
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
        _notifications[index] =
            _notifications[index].copyWith(isRead: true, createdAt: _notifications[index].createdAt);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> refreshOwnerReminders(int ownerId) async {
    _reminders.clear();
    try {
      await Future.wait([
        _generateAppointmentReminders(ownerId),
        _generateVaccinationReminders(ownerId),
        _generateMobileClinicReminders(ownerId),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating reminders: $e');
    }
  }

  Future<void> _generateAppointmentReminders(int ownerId) async {
    final appointments = await DBHelper.instance.getAppointments(ownerId: ownerId);
    final now = DateTime.now();
    for (final raw in appointments) {
      final appointment = Appointment.fromMap(raw);
      final scheduled = DateTime.tryParse(appointment.scheduledAt);
      if (scheduled == null) continue;
      final diff = scheduled.difference(now);
      if (diff.inDays >= 0 && diff.inDays <= 3 && appointment.status != 'completed') {
        final whenText = _formatDuration(diff);
        _reminders.add(
          app_notification.Notification(
            userId: ownerId,
            title: 'Upcoming ${appointment.serviceType}',
            message: whenText == null
                ? 'Your ${appointment.serviceType.toLowerCase()} is scheduled soon.'
                : 'Your ${appointment.serviceType.toLowerCase()} on ${_formatLocalDate(scheduled)} is coming up in $whenText.',
            type: 'reminder',
            createdAt: scheduled.subtract(const Duration(hours: 1)).toIso8601String(),
            data: {
              'appointment_id': appointment.id,
            },
          ),
        );
      }
    }
  }

  Future<void> _generateVaccinationReminders(int ownerId) async {
    final pets = await DBHelper.instance.getPetsByOwner(ownerId);
    final now = DateTime.now();
    for (final pet in pets) {
      final vaccinationData = await DBHelper.instance
          .getVaccinationRecordsByPet(pet['id'] as int);
      for (final recordMap in vaccinationData) {
        final record = VaccinationRecord.fromMap(recordMap);
        if (record.nextDueDate == null) continue;
        final diff = record.nextDueDate!.difference(now);
        if (diff.inDays <= 14) {
          final overdue = diff.isNegative;
          final dueDateText = _formatLocalDate(record.nextDueDate!);
          final windowText = _formatDuration(diff);
          _reminders.add(
            app_notification.Notification(
              userId: ownerId,
              title:
                  overdue ? 'Vaccination overdue' : 'Vaccination due soon',
              message: overdue
                  ? '${record.vaccineName} for ${pet['name']} was due on $dueDateText.'
                  : windowText == null
                      ? '${record.vaccineName} for ${pet['name']} is due on $dueDateText.'
                      : '${record.vaccineName} for ${pet['name']} is due on $dueDateText (in $windowText).',
              type: 'reminder',
              createdAt: (record.nextDueDate ?? now).toIso8601String(),
              data: {
                'pet_id': record.petId,
              },
            ),
          );
        }
      }
    }
  }

  Future<void> _generateMobileClinicReminders(int ownerId) async {
    final requests = await DBHelper.instance.getServiceRequests(
      ownerId: ownerId,
      status: 'approved',
    );
    final now = DateTime.now();
    for (final raw in requests) {
      final request = ServiceRequest.fromMap(raw);
      final scheduled = request.scheduledDate ?? request.requestDate;
      if (scheduled.isBefore(now)) continue;
      final diff = scheduled.difference(now);
      if (diff.inHours <= 24) {
        final arrivalTime = _formatLocalDateTime(scheduled);
        final inText = _formatDuration(diff);
        _reminders.add(
          app_notification.Notification(
            userId: ownerId,
            title: 'Mobile clinic arriving soon',
            message: inText == null
                ? 'Your mobile clinic for ${request.requestType} will arrive around $arrivalTime.'
                : 'Your mobile clinic for ${request.requestType} will arrive in $inText (around $arrivalTime).',
            type: 'reminder',
            createdAt: scheduled.subtract(const Duration(hours: 2)).toIso8601String(),
            data: {
              'request_id': request.id,
            },
          ),
        );
      }
    }
  }

  String? _formatDuration(Duration diff) {
    if (diff.isNegative) {
      final positive = diff.abs();
      if (positive < const Duration(minutes: 1)) {
        return null;
      }
      return _describeDuration(positive);
    }
    if (diff < const Duration(minutes: 1)) {
      return null;
    }
    return _describeDuration(diff);
  }

  String _describeDuration(Duration duration) {
    if (duration.inDays >= 1) {
      final days = duration.inDays;
      return '$days day${days == 1 ? '' : 's'}';
    }
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    final minutes = duration.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }

  String _formatLocalDate(DateTime date) {
    return _dateFormatter.format(date.toLocal());
  }

  String _formatLocalDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final datePart = _dateFormatter.format(local);
    final timePart = _timeFormatter.format(local);
    return '$timePart on $datePart';
  }
}

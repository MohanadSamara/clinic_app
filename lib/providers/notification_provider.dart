import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _scheduledNotifications = [];
  bool _notificationsEnabled = true;
  Map<NotificationType, bool> _notificationPreferences = {
    NotificationType.vaccination: true,
    NotificationType.checkup: true,
    NotificationType.followup: true,
    NotificationType.clinicArrival: true,
    NotificationType.appointment: true,
    NotificationType.urgentCase: true,
    NotificationType.general: true,
  };

  List<AppNotification> get scheduledNotifications => _scheduledNotifications;
  bool get notificationsEnabled => _notificationsEnabled;
  Map<NotificationType, bool> get notificationPreferences =>
      _notificationPreferences;

  NotificationProvider() {
    _loadSettings();
    _loadScheduledNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    // Load notification preferences
    for (var type in NotificationType.values) {
      _notificationPreferences[type] =
          prefs.getBool('notification_${type.name}') ?? true;
    }

    notifyListeners();
  }

  Future<void> _loadScheduledNotifications() async {
    // Load scheduled notifications from storage
    // This would typically load from a local database
    _scheduledNotifications = [];
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    for (var entry in _notificationPreferences.entries) {
      await prefs.setBool('notification_${entry.key.name}', entry.value);
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();

    if (!enabled) {
      // Cancel all scheduled notifications
      await _notificationService.cancelAllNotifications();
      _scheduledNotifications.clear();
    }

    notifyListeners();
  }

  Future<void> setNotificationPreference(
    NotificationType type,
    bool enabled,
  ) async {
    _notificationPreferences[type] = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    if (!_notificationsEnabled || !_notificationPreferences[type]!) {
      return;
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    final notification = AppNotification(
      id: notificationId.toString(),
      title: title,
      body: body,
      type: type,
      scheduledTime: scheduledTime,
      relatedId: relatedId,
      isScheduled: true,
      data: data,
    );

    try {
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: notification.id,
      );

      _scheduledNotifications.add(notification);
      notifyListeners();
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> scheduleVaccinationReminder({
    required String petName,
    required DateTime vaccinationDate,
    String? relatedId,
  }) async {
    final reminderTime = vaccinationDate.subtract(const Duration(days: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    await scheduleNotification(
      title: 'Vaccination Reminder',
      body: 'Don\'t forget to vaccinate $petName tomorrow',
      scheduledTime: reminderTime,
      type: NotificationType.vaccination,
      relatedId: relatedId,
      data: {
        'petName': petName,
        'vaccinationDate': vaccinationDate.toIso8601String(),
      },
    );
  }

  Future<void> scheduleCheckupReminder({
    required String petName,
    required DateTime checkupDate,
    String? relatedId,
  }) async {
    final reminderTime = checkupDate.subtract(const Duration(days: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    await scheduleNotification(
      title: 'Checkup Reminder',
      body: '$petName has a veterinary checkup scheduled for tomorrow',
      scheduledTime: reminderTime,
      type: NotificationType.checkup,
      relatedId: relatedId,
      data: {'petName': petName, 'checkupDate': checkupDate.toIso8601String()},
    );
  }

  Future<void> scheduleFollowupReminder({
    required String petName,
    required DateTime followupDate,
    String? relatedId,
  }) async {
    final reminderTime = followupDate.subtract(const Duration(hours: 2));
    if (reminderTime.isBefore(DateTime.now())) return;

    await scheduleNotification(
      title: 'Follow-up Reminder',
      body: 'Follow-up appointment for $petName in 2 hours',
      scheduledTime: reminderTime,
      type: NotificationType.followup,
      relatedId: relatedId,
      data: {
        'petName': petName,
        'followupDate': followupDate.toIso8601String(),
      },
    );
  }

  Future<void> scheduleAppointmentReminder({
    required String petName,
    required DateTime appointmentTime,
    String? relatedId,
  }) async {
    final reminderTime = appointmentTime.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    await scheduleNotification(
      title: 'Appointment Reminder',
      body: 'Appointment for $petName in 1 hour',
      scheduledTime: reminderTime,
      type: NotificationType.appointment,
      relatedId: relatedId,
      data: {
        'petName': petName,
        'appointmentTime': appointmentTime.toIso8601String(),
      },
    );
  }

  Future<void> scheduleClinicArrivalNotification({
    required String clinicName,
    required DateTime arrivalTime,
    String? relatedId,
  }) async {
    final reminderTime = arrivalTime.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) return;

    await scheduleNotification(
      title: 'Mobile Clinic Arriving',
      body: '$clinicName will arrive at your location in 15 minutes',
      scheduledTime: reminderTime,
      type: NotificationType.clinicArrival,
      relatedId: relatedId,
      data: {
        'clinicName': clinicName,
        'arrivalTime': arrivalTime.toIso8601String(),
      },
    );
  }

  Future<void> cancelNotification(String notificationId) async {
    final notification = _scheduledNotifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );

    await _notificationService.cancelNotification(int.parse(notificationId));
    _scheduledNotifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    _scheduledNotifications.clear();
    notifyListeners();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    if (!_notificationsEnabled || !_notificationPreferences[type]!) {
      return;
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    await _notificationService.showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: notificationId.toString(),
    );
  }
}








// lib/providers/notification_provider.dart
// Migrated to Supabase database (PostgreSQL) - 2026-01-31
// Local notifications still work as before
// OTP Authentication remains UNCHANGED

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/supabase_complete_service.dart';

/// NotificationProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: notifications
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<AppNotification> _notifications = [];
  List<AppNotification> _scheduledNotifications = [];
  bool _notificationsEnabled = true;
  String? _currentUserId;
  Map<NotificationType, bool> _notificationPreferences = {
    NotificationType.vaccination: true,
    NotificationType.checkup: true,
    NotificationType.followup: true,
    NotificationType.clinicArrival: true,
    NotificationType.appointment: true,
    NotificationType.urgentCase: true,
    NotificationType.general: true,
  };

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get scheduledNotifications => _scheduledNotifications;
  bool get notificationsEnabled => _notificationsEnabled;
  Map<NotificationType, bool> get notificationPreferences =>
      _notificationPreferences;

  // Set current user ID for Supabase queries
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    _loadNotificationsFromSupabase();
  }

  // Load notification history from Supabase
  Future<void> _loadNotificationsFromSupabase() async {
    if (_currentUserId == null) return;

    try {
      final notifications = await _supabaseService.getNotificationsByUser(
        _currentUserId!,
      );

      _notifications = notifications.map((data) {
        data['id'] = data['id'] as String?;
        return AppNotification.fromMap(data);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications from Supabase: $e');
    }
  }

  NotificationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    for (var type in NotificationType.values) {
      _notificationPreferences[type] =
          prefs.getBool('notification_${type.name}') ?? true;
    }

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

  // Schedule local notification AND save to Supabase for history
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
      // Schedule local notification
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

  // Create notification in Supabase (for cloud sync)
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    if (_currentUserId == null) return;

    try {
      final notificationData = {
        'user_id': _currentUserId,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'related_id': relatedId,
        'data': data,
        'is_read': false,
        'is_scheduled': false,
      };

      await _supabaseService.insertNotification(notificationData);
    } catch (e) {
      debugPrint('Error creating notification in Supabase: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    if (_currentUserId == null) return 0;

    try {
      return await _supabaseService.getUnreadNotificationCount(_currentUserId!);
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
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

    // Also create in Supabase for cloud sync
    await createNotification(
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      data: data,
    );
  }
}

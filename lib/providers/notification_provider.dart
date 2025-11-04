// lib/providers/notification_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../models/notification.dart' as NotifModel;

/// In-app notifications state manager backed by the local DB.
/// This scaffolds cross-cutting notifications requirements:
/// - Load per-user notifications (optionally unread only)
/// - Insert/send in-app notifications
/// - Mark as read
/// - Get unread count
/// - Stubs for scheduling reminders (to be wired with OS/local push later)
class NotificationProvider extends ChangeNotifier {
  final List<NotifModel.Notification> _items = [];
  bool _loading = false;

  List<NotifModel.Notification> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;

  Future<void> loadForUser(int userId, {bool unreadOnly = false}) async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await DBHelper.instance.getNotificationsByUser(
        userId,
        unreadOnly: unreadOnly,
      );
      _items
        ..clear()
        ..addAll(rows.map((m) => NotifModel.Notification.fromMap(m)));
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.loadForUser error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> send({
    required int userId,
    required String title,
    required String message,
    String type = 'update', // 'reminder', 'alert', 'update', 'audit'
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool isRead = false,
  }) async {
    try {
      final id = await DBHelper.instance.insertNotification({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead ? 1 : 0,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'data': data == null ? null : jsonEncode(data),
      });

      // Optimistically update local list for the active user feed if relevant
      // Note: callers should reload if they need strict consistency
      return id;
    } catch (e) {
      debugPrint('NotificationProvider.send error: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await DBHelper.instance.markNotificationAsRead(id);
      final idx = _items.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final n = _items[idx];
        _items[idx] = NotifModel.Notification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
          data: n.data,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationProvider.markAsRead error: $e');
    }
  }

  Future<int> getUnreadCount(int userId) async {
    try {
      return await DBHelper.instance.getUnreadNotificationCount(userId);
    } catch (e) {
      debugPrint('NotificationProvider.getUnreadCount error: $e');
      return 0;
    }
  }

  /// Placeholder for scheduling reminders (vaccinations, checkups, ETA).
  /// This scaffolds the API; actual OS scheduling (local push) can be wired
  /// later using flutter_local_notifications or platform channels.
  Future<bool> scheduleReminder({
    required int userId,
    required String title,
    required String message,
    required DateTime when,
    Map<String, dynamic>? data,
  }) async {
    // For now, we insert a record with the scheduled timestamp.
    // A future background service can dispatch it at the right time.
    try {
      await send(
        userId: userId,
        title: title,
        message: message,
        type: 'reminder',
        data: {
          'scheduled_for': when.toIso8601String(),
          if (data != null) ...data,
        },
        createdAt: when,
        isRead: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

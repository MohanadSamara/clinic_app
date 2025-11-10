import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class OwnerNotificationsScreen extends StatefulWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  State<OwnerNotificationsScreen> createState() =>
      _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState extends State<OwnerNotificationsScreen> {
  final _formatter = DateFormat('yMMMd – jm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id == null) return;
    final provider = context.read<NotificationProvider>();
    await provider.loadNotifications(auth.user!.id!);
    await provider.refreshOwnerReminders(auth.user!.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders & Notifications')),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final notifications = notificationProvider.notifications;
            if (notificationProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (notifications.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.notifications_none, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'You are all caught up! Reminders will appear here as they become available.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final timestamp = DateTime.tryParse(notification.createdAt);
                return Card(
                  child: ListTile(
                    leading: Icon(_iconForType(notification.type)),
                    title: Text(notification.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.message),
                        if (timestamp != null)
                          Text(
                            _formatter.format(timestamp),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    trailing: notification.id != null
                        ? IconButton(
                            icon: Icon(
                              notification.isRead
                                  ? Icons.mark_email_read
                                  : Icons.mark_email_unread,
                            ),
                            onPressed: notification.isRead
                                ? null
                                : () => _markAsRead(notification.id!),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reminder':
        return Icons.alarm;
      case 'dispatch':
        return Icons.local_shipping;
      case 'alert':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAsRead(int id) async {
    await context.read<NotificationProvider>().markAsRead(id);
  }
}

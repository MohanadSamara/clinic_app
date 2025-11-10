// lib/screens/owner/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/vaccination_record.dart';
import '../../models/notification.dart' as app;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthProvider>();
    final ownerId = auth.user?.id;
    if (ownerId == null) return;
    setState(() => _loading = true);

    final appointmentProvider = context.read<AppointmentProvider>();
    await appointmentProvider.loadAppointments(ownerId: ownerId);

    final petProvider = context.read<PetProvider>();
    await petProvider.loadPets(ownerId: ownerId);
    final vaccinations = <VaccinationRecord>[];
    for (final pet in petProvider.pets) {
      if (pet.id == null) continue;
      await petProvider.loadVaccinationRecords(pet.id!);
      vaccinations.addAll(petProvider.getVaccinationRecordsByPet(pet.id!));
    }

    await context.read<NotificationProvider>().syncOwnerReminders(
          ownerId: ownerId,
          appointments: appointmentProvider.getAppointmentsByOwner(ownerId),
          vaccinations: vaccinations,
        );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (_loading || provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = provider.notifications;
            if (notifications.isEmpty) {
              return const ListTile(
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('No notifications yet'),
                subtitle: Text('Reminders for vaccinations, visits, and mobile clinic arrivals will appear here.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final app.Notification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final timestamp = DateTime.tryParse(notification.createdAt)?.toLocal();
    return Card(
      child: ListTile(
        leading: Icon(
          _iconForType(notification.type),
          color: _colorForType(notification.type),
        ),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            if (timestamp != null)
              Text(
                'Received ${timestamp.toString().split('.').first}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : TextButton(
                onPressed: () => provider.markAsRead(notification.id!),
                child: const Text('Mark read'),
              ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reminder':
        return Icons.alarm;
      case 'appointment':
        return Icons.medical_services;
      case 'alert':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'reminder':
        return Colors.teal;
      case 'appointment':
        return Colors.blue;
      case 'alert':
        return Colors.redAccent;
      default:
        return Colors.deepPurple;
    }
  }
}

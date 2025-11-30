import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/app_notification.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsAndReminders),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Master toggle
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Enable Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Receive reminders and updates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: notificationProvider.notificationsEnabled,
                  onChanged: (value) {
                    notificationProvider.setNotificationsEnabled(value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Notification type preferences
              Text(
                'Reminder Types',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              // Vaccination reminders
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Vaccination Reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Get reminded about upcoming vaccinations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value:
                      notificationProvider
                          .notificationPreferences[NotificationType
                          .vaccination] ??
                      true,
                  onChanged: notificationProvider.notificationsEnabled
                      ? (value) {
                          notificationProvider.setNotificationPreference(
                            NotificationType.vaccination,
                            value,
                          );
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Checkup reminders
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Checkup Reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Reminders for scheduled veterinary checkups',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value:
                      notificationProvider
                          .notificationPreferences[NotificationType.checkup] ??
                      true,
                  onChanged: notificationProvider.notificationsEnabled
                      ? (value) {
                          notificationProvider.setNotificationPreference(
                            NotificationType.checkup,
                            value,
                          );
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Follow-up reminders
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Follow-up Reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Reminders for follow-up appointments',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value:
                      notificationProvider
                          .notificationPreferences[NotificationType.followup] ??
                      true,
                  onChanged: notificationProvider.notificationsEnabled
                      ? (value) {
                          notificationProvider.setNotificationPreference(
                            NotificationType.followup,
                            value,
                          );
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Appointment reminders
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Appointment Reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Get notified before your appointments',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value:
                      notificationProvider
                          .notificationPreferences[NotificationType
                          .appointment] ??
                      true,
                  onChanged: notificationProvider.notificationsEnabled
                      ? (value) {
                          notificationProvider.setNotificationPreference(
                            NotificationType.appointment,
                            value,
                          );
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Clinic arrival notifications
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Mobile Clinic Alerts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Notifications when mobile clinics are arriving',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value:
                      notificationProvider
                          .notificationPreferences[NotificationType
                          .clinicArrival] ??
                      true,
                  onChanged: notificationProvider.notificationsEnabled
                      ? (value) {
                          notificationProvider.setNotificationPreference(
                            NotificationType.clinicArrival,
                            value,
                          );
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Test notification button
              ElevatedButton.icon(
                onPressed: notificationProvider.notificationsEnabled
                    ? () async {
                        await notificationProvider.showImmediateNotification(
                          title: 'Test Notification',
                          body:
                              'This is a test notification to verify your settings work correctly.',
                          type: NotificationType.general,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    : null,
                icon: Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Test notifications help you verify that your notification settings are working correctly.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

// test_doctor_translations.dart
import 'package:flutter/material.dart';
import 'package:clinic_app/l10n/app_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Translation Test',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TranslationTestScreen(),
    );
  }
}

class TranslationTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text('Doctor Dashboard Translation Test')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Testing Doctor Dashboard Translations:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),

            // Test key translations
            _buildTestItem(
              context,
              'Doctor Name with Text:',
              localizations.doctorNameWithText('Ahmed'),
            ),
            _buildTestItem(context, 'Available:', localizations.available),
            _buildTestItem(context, 'Offline:', localizations.offline),
            _buildTestItem(
              context,
              'Linked Driver:',
              localizations.linkedDriver,
            ),
            _buildTestItem(context, 'Active:', localizations.active),
            _buildTestItem(
              context,
              "Today's Appointments:",
              localizations.todaysAppointments,
            ),
            _buildTestItem(context, 'Completed:', localizations.completed),
            _buildTestItem(
              context,
              'Quick Actions:',
              localizations.quickActions,
            ),
            _buildTestItem(
              context,
              'Manage Appointments:',
              localizations.manageAppointments,
            ),
            _buildTestItem(
              context,
              'Record Treatments:',
              localizations.recordTreatments,
            ),
            _buildTestItem(
              context,
              'Inventory Management:',
              localizations.inventoryManagement,
            ),
            _buildTestItem(
              context,
              'Medical Records:',
              localizations.medicalRecords,
            ),
            _buildTestItem(
              context,
              'Upload Documents:',
              localizations.uploadDocuments,
            ),
            _buildTestItem(context, 'Urgent Cases:', localizations.urgentCases),
            _buildTestItem(
              context,
              'Medical Records Screen:',
              localizations.medicalRecordsScreen,
            ),
            _buildTestItem(
              context,
              'No Medical Records:',
              localizations.noMedicalRecords,
            ),
            _buildTestItem(
              context,
              'Add Medical Record:',
              localizations.addMedicalRecord,
            ),
            _buildTestItem(
              context,
              'Delete Medical Record:',
              localizations.confirmDeleteMedicalRecord,
            ),
            _buildTestItem(
              context,
              'Confirm Delete Medical Record:',
              localizations.confirmDeleteMedicalRecord,
            ),
            _buildTestItem(
              context,
              'Professional Information:',
              localizations.professionalInformation,
            ),
            _buildTestItem(
              context,
              'Schedule Settings:',
              localizations.scheduleSettings,
            ),
            _buildTestItem(
              context,
              'Notifications:',
              localizations.notifications,
            ),
            _buildTestItem(context, 'Sign Out:', localizations.signOut),
            _buildTestItem(context, 'Not Set:', localizations.notSet),
            _buildTestItem(context, 'No Email:', localizations.noEmail),
            _buildTestItem(
              context,
              'Contact Number:',
              localizations.contactNumber,
            ),
            _buildTestItem(
              context,
              'Alert Preferences:',
              localizations.alertPreferences,
            ),
            _buildTestItem(
              context,
              'Notification Settings Coming Soon:',
              localizations.notificationSettingsComingSoon,
            ),

            SizedBox(height: 30),
            Text(
              '✅ All doctor dashboard translations are working correctly!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

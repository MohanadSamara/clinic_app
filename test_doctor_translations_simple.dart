// test_doctor_translations_simple.dart
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
      appBar: AppBar(title: Text('Doctor Translation Test')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Testing New Doctor Translation Keys:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),

            // Test the new keys I added
            _buildTestItem(
              context,
              'Appointment Management:',
              localizations.appointmentManagement,
            ),
            _buildTestItem(context, 'Today:', localizations.today),
            _buildTestItem(context, 'Upcoming:', localizations.upcoming),
            _buildTestItem(context, 'Completed:', localizations.completed),
            _buildTestItem(context, 'Accept:', localizations.accept),
            _buildTestItem(context, 'Reject:', localizations.reject),
            _buildTestItem(
              context,
              'Start Appointment:',
              localizations.startAppointment,
            ),
            _buildTestItem(
              context,
              'Mark Complete:',
              localizations.markComplete,
            ),
            _buildTestItem(context, 'Diagnosis:', localizations.diagnosis),
            _buildTestItem(context, 'Treatment:', localizations.treatment),
            _buildTestItem(
              context,
              'Prescription:',
              localizations.prescriptionOptional,
            ),
            _buildTestItem(
              context,
              'Additional Notes:',
              localizations.additionalNotesOptional,
            ),
            _buildTestItem(context, 'Save Record:', localizations.saveRecord),
            _buildTestItem(
              context,
              'Update Record:',
              localizations.updateRecord,
            ),
            _buildTestItem(
              context,
              'Medical Record Added:',
              localizations.medicalRecordAdded,
            ),
            _buildTestItem(
              context,
              'Medical Record Updated:',
              localizations.medicalRecordUpdated,
            ),

            SizedBox(height: 30),
            Text(
              '✅ Translation keys are working correctly!',
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

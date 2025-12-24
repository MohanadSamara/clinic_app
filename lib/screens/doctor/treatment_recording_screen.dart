// lib/screens/doctor/treatment_recording_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medical_record.dart';

class TreatmentRecordingScreen extends StatefulWidget {
  const TreatmentRecordingScreen({super.key});

  @override
  State<TreatmentRecordingScreen> createState() =>
      _TreatmentRecordingScreenState();
}

class _TreatmentRecordingScreenState extends State<TreatmentRecordingScreen> {
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int? _selectedPetId;
  bool _isEmergency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        context.read<MedicalProvider>().loadMedicalRecords(
          doctorId: authProvider.user!.id!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Recording'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showTreatmentHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record New Treatment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TODO: Pet selection dropdown
                    const Text('Pet selection will be implemented'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Emergency Case'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isEmergency,
                          onChanged: (value) =>
                              setState(() => _isEmergency = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Medical Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _diagnosisController,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosis',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _treatmentController,
                      decoration: const InputDecoration(
                        labelText: 'Treatment Provided',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _prescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Prescription (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTreatmentRecord,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Treatment Record'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Treatments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<MedicalProvider>(
              builder: (context, medicalProvider, child) {
                if (medicalProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recentRecords = medicalProvider.medicalRecords
                    .take(5)
                    .toList();

                if (recentRecords.isEmpty) {
                  return const Center(child: Text('No treatment records yet'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentRecords.length,
                  itemBuilder: (context, index) {
                    final record = recentRecords[index];
                    return _TreatmentRecordCard(record: record);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveTreatmentRecord() async {
    if (_diagnosisController.text.isEmpty ||
        _treatmentController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in diagnosis and treatment'),
          ),
        );
      }
      return;
    }

    if (_selectedPetId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a patient')),
        );
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id == null) return;

    final record = MedicalRecord(
      petId: _selectedPetId!,
      doctorId: authProvider.user!.id!,
      diagnosis: _diagnosisController.text,
      treatment: _treatmentController.text,
      prescription: _prescriptionController.text.isEmpty
          ? null
          : _prescriptionController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      date: DateTime.now().toIso8601String(),
    );

    final success = await context.read<MedicalProvider>().addMedicalRecord(
      record,
    );

    if (mounted) {
      if (success) {
        // Clear form
        _diagnosisController.clear();
        _treatmentController.clear();
        _prescriptionController.clear();
        _notesController.clear();
        setState(() => _isEmergency = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treatment record saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save treatment record')),
        );
      }
    }
  }

  void _showTreatmentHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TreatmentHistoryScreen()),
    );
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _TreatmentRecordCard extends StatelessWidget {
  final MedicalRecord record;

  const _TreatmentRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Patient ID: ${record.petId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  record.date.split('T')[0],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Diagnosis: ${record.diagnosis}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              'Treatment: ${record.treatment}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (record.prescription != null &&
                record.prescription!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Prescription: ${record.prescription}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TreatmentHistoryScreen extends StatelessWidget {
  const TreatmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treatment History')),
      body: Consumer<MedicalProvider>(
        builder: (context, medicalProvider, child) {
          if (medicalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (medicalProvider.medicalRecords.isEmpty) {
            return const Center(child: Text('No treatment records found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicalProvider.medicalRecords.length,
            itemBuilder: (context, index) {
              final record = medicalProvider.medicalRecords[index];
              return _DetailedTreatmentRecordCard(record: record);
            },
          );
        },
      ),
    );
  }
}

class _DetailedTreatmentRecordCard extends StatelessWidget {
  final MedicalRecord record;

  const _DetailedTreatmentRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Patient ID: ${record.petId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  record.date.split('T')[0],
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Diagnosis', record.diagnosis),
            _buildDetailRow('Treatment', record.treatment),
            if (record.prescription != null && record.prescription!.isNotEmpty)
              _buildDetailRow('Prescription', record.prescription!),
            if (record.notes != null && record.notes!.isNotEmpty)
              _buildDetailRow('Notes', record.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}








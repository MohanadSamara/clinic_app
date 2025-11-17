// lib/screens/owner/medical_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medical_record.dart';
import '../../models/pet.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final Pet pet;

  const MedicalHistoryScreen({super.key, required this.pet});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicalRecords();
    });
  }

  Future<void> _loadMedicalRecords() async {
    if (widget.pet.id != null) {
      await context.read<MedicalProvider>().loadMedicalRecordsByPet(
        widget.pet.id!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pet.name} - Medical History'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, animationValue, child) {
          return Opacity(
            opacity: animationValue,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - animationValue)),
              child: Consumer<MedicalProvider>(
                builder: (context, medicalProvider, child) {
                  if (medicalProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final records = medicalProvider.getMedicalRecordsByPet(
                    widget.pet.id ?? 0,
                  );

                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No medical records found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Medical records will appear here after veterinary visits',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort records by date (newest first)
                  final sortedRecords = records.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, listValue, child) {
                      return Opacity(
                        opacity: listValue,
                        child: Transform.translate(
                          offset: Offset(30 * (1 - listValue), 0),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedRecords.length,
                            itemBuilder: (context, index) {
                              final record = sortedRecords[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 400 + (index * 100),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, cardValue, child) {
                                  return Transform.translate(
                                    offset: Offset(-30 * (1 - cardValue), 0),
                                    child: Opacity(
                                      opacity: cardValue,
                                      child: _MedicalRecordCard(record: record),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;

  const _MedicalRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    // Parse date for better display
    final date = DateTime.tryParse(record.date);
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : record.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Visit',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Diagnosis Section
            _buildDetailSection(
              context,
              'Diagnosis',
              record.diagnosis,
              Icons.local_hospital,
              Colors.red.shade100,
              Colors.red,
            ),

            const SizedBox(height: 16),

            // Treatment Section
            _buildDetailSection(
              context,
              'Treatment',
              record.treatment,
              Icons.healing,
              Colors.green.shade100,
              Colors.green,
            ),

            // Prescription Section (if available)
            if (record.prescription != null &&
                record.prescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                'Prescription',
                record.prescription!,
                Icons.medication,
                Colors.blue.shade100,
                Colors.blue,
              ),
            ],

            // Notes Section (if available)
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                'Additional Notes',
                record.notes!,
                Icons.note,
                Colors.purple.shade100,
                Colors.purple,
              ),
            ],

            // Attachments indicator (if available)
            if (record.attachments != null &&
                record.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${record.attachments!.length} attachment${record.attachments!.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

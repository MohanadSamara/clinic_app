// lib/screens/owner/medical_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medical_record.dart';
import '../../models/document.dart';
import '../../models/pet.dart';
import '../../theme/app_theme.dart';
import '../../components/ui_kit.dart';

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
                    return EmptyState(
                      icon: Icons.history,
                      title: 'No records yet',
                      message: 'Your pet\'s past visits will appear here.',
                    );
                  }

                  // Sort records by date (newest first)
                  final sortedRecords = records.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return Column(
                    children: [
                      SectionHeader(
                        title: 'Medical History',
                        subtitle: 'Past visits and treatments',
                      ),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
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
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ),
                                      duration: Duration(
                                        milliseconds: 400 + (index * 100),
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, cardValue, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            -30 * (1 - cardValue),
                                            0,
                                          ),
                                          child: Opacity(
                                            opacity: cardValue,
                                            child: _MedicalRecordCard(
                                              record: record,
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
                      ),
                    ],
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

class _MedicalRecordCard extends StatefulWidget {
  final MedicalRecord record;

  const _MedicalRecordCard({required this.record});

  @override
  State<_MedicalRecordCard> createState() => _MedicalRecordCardState();
}

class _MedicalRecordCardState extends State<_MedicalRecordCard> {
  List<Document> _documents = [];
  bool _loadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (widget.record.id == null) return;

    setState(() => _loadingDocuments = true);
    try {
      final documentProvider = context.read<DocumentProvider>();
      await documentProvider.loadDocuments(medicalRecordId: widget.record.id!);
      if (mounted) {
        setState(() => _documents = documentProvider.documents);
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingDocuments = false);
      }
    }
  }

  Future<void> _downloadDocument(Document document) async {
    final success = await context.read<DocumentProvider>().downloadDocument(
      document,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Document downloaded successfully'
                : 'Failed to download document',
          ),
        ),
      );
    }
  }

  Widget _buildDocumentsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Documents (${_documents.length})',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.fileName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    onPressed: () => _downloadDocument(doc),
                    tooltip: 'Download',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parse date for better display
    final date = DateTime.tryParse(widget.record.date);
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : widget.record.date;

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
                        widget.record.diagnosis,
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Medical Visit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
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
              widget.record.diagnosis,
              Icons.local_hospital,
              Colors.red.shade100,
              Colors.red,
            ),

            const SizedBox(height: 16),

            // Treatment Section
            _buildDetailSection(
              context,
              'Treatment',
              widget.record.treatment,
              Icons.healing,
              Colors.green.shade100,
              Colors.green,
            ),

            // Prescription Section (if available)
            if (widget.record.prescription != null &&
                widget.record.prescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                'Prescription',
                widget.record.prescription!,
                Icons.medication,
                Colors.blue.shade100,
                Colors.blue,
              ),
            ],

            // Notes Section (if available)
            if (widget.record.notes != null &&
                widget.record.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                'Additional Notes',
                widget.record.notes!,
                Icons.note,
                Colors.purple.shade100,
                Colors.purple,
              ),
            ],

            // Documents Section
            if (_loadingDocuments) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ] else if (_documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDocumentsSection(),
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

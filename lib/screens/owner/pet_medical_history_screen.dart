// lib/screens/owner/pet_medical_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/pet.dart';
import '../../models/vaccination_record.dart';
import '../../models/medical_record.dart';
import '../../providers/pet_provider.dart';

class PetMedicalHistoryScreen extends StatefulWidget {
  final Pet pet;

  const PetMedicalHistoryScreen({super.key, required this.pet});

  @override
  State<PetMedicalHistoryScreen> createState() =>
      _PetMedicalHistoryScreenState();
}

class _PetMedicalHistoryScreenState extends State<PetMedicalHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pet.id != null) {
        context.read<PetProvider>().loadPetDetails(widget.pet.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(
        title: Text('${pet.name} - Medical history'),
        actions: [
          if (_generatingPdf)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Download PDF summary',
              onPressed: _downloadPdf,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVaccinationDialog,
        icon: const Icon(Icons.vaccines),
        label: const Text('Add vaccination'),
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          final medicalRecords = petProvider.getMedicalRecordsByPet(pet.id ?? -1);
          final vaccinations =
              petProvider.getVaccinationRecordsByPet(pet.id ?? -1);
          final documents = petProvider.getDocumentsByPet(pet.id ?? -1);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('${pet.species} ${pet.breed ?? ''}'.trim()),
                      if (pet.dob != null)
                        Text('Age: ${_calculateAge(pet.dob!)}'),
                      if (pet.medicalHistorySummary != null &&
                          pet.medicalHistorySummary!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          pet.medicalHistorySummary!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                      if (pet.vaccinationStatus != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.verified_user, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pet.vaccinationStatus!['notes'] ??
                                    'Vaccination details available',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Recent treatments'),
              if (medicalRecords.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No treatment records yet'),
                  ),
                )
              else
                ...medicalRecords.map((record) => _MedicalRecordTile(record)),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Vaccination schedule'),
              if (vaccinations.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.vaccines_outlined),
                    title: Text('No vaccinations recorded'),
                  ),
                )
              else
                ...vaccinations.map((record) => _VaccinationRecordTile(
                      record: record,
                      formatDate: _dateFormat,
                    )),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Documents & images'),
              if (documents.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined),
                    title: Text('No documents uploaded yet'),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: documents
                        .map(
                          (doc) => ListTile(
                            leading: const Icon(Icons.attachment),
                            title: Text(doc.fileName),
                            subtitle: Text(
                              'Uploaded ${_dateFormat.format(doc.uploadDate)}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (widget.pet.id == null) return;
    final petProvider = context.read<PetProvider>();
    final medicalRecords = petProvider.getMedicalRecordsByPet(widget.pet.id!);
    final vaccinations = petProvider.getVaccinationRecordsByPet(widget.pet.id!);
    final documents = petProvider.getDocumentsByPet(widget.pet.id!);

    setState(() => _generatingPdf = true);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('${widget.pet.name} - Medical history',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 8),
          pw.Text('Species: ${widget.pet.species} ${widget.pet.breed ?? ''}'),
          if (widget.pet.dob != null)
            pw.Text('Date of birth: ${widget.pet.dob}'),
          if (widget.pet.medicalHistorySummary != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text('Summary: ${widget.pet.medicalHistorySummary}'),
            ),
          pw.SizedBox(height: 16),
          pw.Text('Treatments',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (medicalRecords.isEmpty)
            pw.Text('No treatment records yet')
          else
            ...medicalRecords.map(
              (record) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: ${record.date.split('T').first}'),
                    pw.Text('Diagnosis: ${record.diagnosis}'),
                    pw.Text('Treatment: ${record.treatment}'),
                    if (record.prescription != null)
                      pw.Text('Prescription: ${record.prescription}'),
                    if (record.notes != null)
                      pw.Text('Notes: ${record.notes}'),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text('Vaccinations',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (vaccinations.isEmpty)
            pw.Text('No vaccinations recorded')
          else
            ...vaccinations.map(
              (record) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '${record.vaccineName} on ${_dateFormat.format(record.vaccinationDate)}'
                  '${record.nextDueDate != null ? ' • Next due ${_dateFormat.format(record.nextDueDate!)}' : ''}',
                ),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text('Documents',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (documents.isEmpty)
            pw.Text('No documents uploaded')
          else
            ...documents.map(
              (doc) => pw.Text(
                '${doc.fileName} • uploaded ${_dateFormat.format(doc.uploadDate)}',
              ),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${widget.pet.name}_medical_history.pdf',
    );

    if (mounted) {
      setState(() => _generatingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated successfully')),
      );
    }
  }

  Future<void> _showAddVaccinationDialog() async {
    if (widget.pet.id == null) return;
    final result = await showDialog<VaccinationRecord>(
      context: context,
      builder: (context) => _VaccinationDialog(petId: widget.pet.id!),
    );

    if (result != null && mounted) {
      final success =
          await context.read<PetProvider>().addVaccinationRecord(result);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaccination record added')), 
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  String _calculateAge(String isoDate) {
    try {
      final dob = DateTime.parse(isoDate);
      final now = DateTime.now();
      final years = now.year - dob.year - ((now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day))
          ? 1
          : 0);
      if (years <= 0) {
        final months = now.difference(dob).inDays ~/ 30;
        return '$months month${months == 1 ? '' : 's'}';
      }
      return '$years year${years == 1 ? '' : 's'}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _MedicalRecordTile extends StatelessWidget {
  final MedicalRecord record;

  const _MedicalRecordTile(this.record);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(record.date);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medical_services),
        title: Text(record.diagnosis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date != null) Text(DateFormat('MMM d, yyyy').format(date)),
            Text('Treatment: ${record.treatment}'),
            if (record.prescription != null)
              Text('Prescription: ${record.prescription}'),
            if (record.notes != null) Text('Notes: ${record.notes}'),
          ],
        ),
      ),
    );
  }
}

class _VaccinationRecordTile extends StatelessWidget {
  final VaccinationRecord record;
  final DateFormat formatDate;

  const _VaccinationRecordTile({
    required this.record,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.vaccines),
        title: Text(record.vaccineName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Given on ${formatDate.format(record.vaccinationDate)}'),
            if (record.nextDueDate != null)
              Text('Next due ${formatDate.format(record.nextDueDate!)}'),
            if (record.batchNumber != null)
              Text('Batch: ${record.batchNumber}'),
            if (record.notes != null) Text(record.notes!),
          ],
        ),
      ),
    );
  }
}

class _VaccinationDialog extends StatefulWidget {
  final int petId;

  const _VaccinationDialog({required this.petId});

  @override
  State<_VaccinationDialog> createState() => _VaccinationDialogState();
}

class _VaccinationDialogState extends State<_VaccinationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _vaccinationDate = DateTime.now();
  DateTime? _nextDueDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add vaccination record'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Vaccine name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Administered ${DateFormat('MMM d, yyyy').format(_vaccinationDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _vaccinationDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _vaccinationDate = date);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available),
                title: Text(
                  _nextDueDate == null
                      ? 'Set next due date'
                      : 'Next due ${DateFormat('MMM d, yyyy').format(_nextDueDate!)}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _nextDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) {
                    setState(() => _nextDueDate = date);
                  }
                },
              ),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(labelText: 'Batch number'),
              ),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (storage, reaction)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              VaccinationRecord(
                petId: widget.petId,
                vaccineName: _nameController.text,
                vaccinationDate: _vaccinationDate,
                nextDueDate: _nextDueDate,
                batchNumber:
                    _batchController.text.isEmpty ? null : _batchController.text,
                notes: _notesController.text.isEmpty ? null : _notesController.text,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

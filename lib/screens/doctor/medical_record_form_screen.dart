// lib/screens/doctor/medical_record_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medical_record.dart';
import '../../models/pet.dart';
import '../../models/appointment.dart';
import '../../models/document.dart';

class MedicalRecordFormScreen extends StatefulWidget {
  final MedicalRecord? record;
  final Pet? pet;
  final Appointment? appointment;

  const MedicalRecordFormScreen({
    super.key,
    this.record,
    this.pet,
    this.appointment,
  });

  @override
  State<MedicalRecordFormScreen> createState() =>
      _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends State<MedicalRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  MedicalRecord? _savedRecord;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      // Editing existing record
      _diagnosisController.text = widget.record!.diagnosis;
      _treatmentController.text = widget.record!.treatment;
      _prescriptionController.text = widget.record!.prescription ?? '';
      _notesController.text = widget.record!.notes ?? '';
      _selectedDate = DateTime.tryParse(widget.record!.date) ?? DateTime.now();
    } else {
      // New record - set date to today
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showFileUploadOption() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Supporting Documents',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload medical documents, lab results, or images related to this record',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pop(); // Close form screen
                      },
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip for Now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToFileUpload();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Files'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFileUpload() {
    // Navigate to file upload screen with the pet information
    Navigator.of(
      context,
    ).pushNamed('/doctor/document-upload', arguments: {'pet': widget.pet});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final doctorId = authProvider.user?.id;

      if (doctorId == null) {
        throw Exception('Doctor not authenticated');
      }

      int petId;
      if (widget.record != null) {
        // Editing existing record
        petId = widget.record!.petId;
      } else if (widget.pet != null) {
        // New record for specific pet
        petId = widget.pet!.id!;
      } else if (widget.appointment != null) {
        // New record from appointment
        petId = widget.appointment!.petId;
      } else {
        throw Exception('No pet specified for medical record');
      }

      final record = MedicalRecord(
        id: widget.record?.id,
        petId: petId,
        doctorId: doctorId,
        diagnosis: _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim(),
        prescription: _prescriptionController.text.trim().isEmpty
            ? null
            : _prescriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        date: _selectedDate.toIso8601String(),
      );

      final success = widget.record == null
          ? await context.read<MedicalProvider>().addMedicalRecord(record)
          : await context.read<MedicalProvider>().updateMedicalRecord(record);

      if (success && mounted) {
        setState(() {
          _savedRecord = record;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.record == null
                  ? 'Medical record added successfully'
                  : 'Medical record updated successfully',
            ),
          ),
        );

        // Show option to upload files after successful save (only for new records)
        if (widget.record == null) {
          _showFileUploadOption();
        } else {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to save medical record');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.record != null;
    final petName =
        widget.pet?.name ??
        'Pet ID: ${widget.appointment?.petId ?? widget.record?.petId ?? 'Unknown'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medical Record' : 'Add Medical Record'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, headerValue, child) {
                          return Opacity(
                            opacity: headerValue,
                            child: Transform.translate(
                              offset: Offset(-30 * (1 - headerValue), 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Edit Medical Record'
                                        : 'Add Medical Record',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pet: $petName',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Date Selection
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, dateValue, child) {
                          return Opacity(
                            opacity: dateValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - dateValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Visit Date',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      InkWell(
                                        onTap: () => _selectDate(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge,
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Diagnosis Field
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, diagnosisValue, child) {
                          return Opacity(
                            opacity: diagnosisValue,
                            child: Transform.translate(
                              offset: Offset(-30 * (1 - diagnosisValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_hospital,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Diagnosis',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _diagnosisController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          hintText: 'Describe the diagnosis...',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Diagnosis is required';
                                          }
                                          if (value.trim().length < 10) {
                                            return 'Please provide a detailed diagnosis';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Treatment Field
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, treatmentValue, child) {
                          return Opacity(
                            opacity: treatmentValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - treatmentValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.healing,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Treatment',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _treatmentController,
                                        maxLines: 4,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Describe the treatment provided...',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Treatment is required';
                                          }
                                          if (value.trim().length < 10) {
                                            return 'Please provide detailed treatment information';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Prescription Field
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, prescriptionValue, child) {
                          return Opacity(
                            opacity: prescriptionValue,
                            child: Transform.translate(
                              offset: Offset(-30 * (1 - prescriptionValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.medication,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Prescription (Optional)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _prescriptionController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'List prescribed medications and dosages...',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Notes Field
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1100),
                        builder: (context, notesValue, child) {
                          return Opacity(
                            opacity: notesValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - notesValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.note,
                                            color: Colors.purple,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Additional Notes (Optional)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _notesController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Any additional observations or follow-up instructions...',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Buttons
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, buttonValue, child) {
                          return Opacity(
                            opacity: buttonValue,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - buttonValue)),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _saveMedicalRecord,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              isEditing
                                                  ? 'Update Record'
                                                  : 'Save Record',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// lib/screens/owner/pet_management_screen.dart
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pet.dart';
import '../../models/document.dart';
import '../../models/vaccination_record.dart';
import '../../models/medical_record.dart';

class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  State<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user != null && user.id != null) {
        _loadPetsAndDetails(user.id!);
      }
    });
  }

  Future<void> _loadPetsAndDetails(int ownerId) async {
    final petProvider = context.read<PetProvider>();
    await petProvider.loadPets(ownerId: ownerId);
    for (final pet in petProvider.pets) {
      if (pet.id != null) {
        await petProvider.loadDocuments(pet.id!);
        await petProvider.loadVaccinationRecords(pet.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPetDialog(context),
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No pets registered yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddPetDialog(context),
                    child: const Text('Add Your First Pet'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: petProvider.pets.length,
            itemBuilder: (context, index) {
              final pet = petProvider.pets[index];
              final documents =
                  pet.id != null ? petProvider.getDocumentsByPet(pet.id!) : [];
              final vaccinations = pet.id != null
                  ? petProvider.getVaccinationRecordsForPet(pet.id!)
                  : <VaccinationRecord>[];
              return _PetCard(
                pet: pet,
                onEdit: () => _showEditPetDialog(context, pet),
                onDelete: () => _showDeleteConfirmation(context, pet),
                onViewMedicalHistory: () =>
                    _navigateToMedicalHistory(context, pet),
                onAddDocument: pet.id == null
                    ? null
                    : () => _showAddDocumentSheet(context, pet.id!),
                onAddVaccination: pet.id == null
                    ? null
                    : () => _showVaccinationDialog(context, pet.id!),
                documents: documents,
                vaccinations: vaccinations,
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEditPetDialog(),
    );
  }

  void _showEditPetDialog(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => _AddEditPetDialog(pet: pet),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (pet.id != null) {
                await context.read<PetProvider>().deletePet(pet.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${pet.name} deleted successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToMedicalHistory(BuildContext context, Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MedicalHistoryScreen(pet: pet)),
    );
  }

  void _showAddDocumentSheet(BuildContext context, int petId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddDocumentSheet(petId: petId),
      ),
    );
  }

  void _showVaccinationDialog(BuildContext context, int petId) {
    showDialog(
      context: context,
      builder: (context) => _AddVaccinationRecordDialog(petId: petId),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewMedicalHistory;
  final VoidCallback? onAddDocument;
  final VoidCallback? onAddVaccination;
  final List<Document> documents;
  final List<VaccinationRecord> vaccinations;

  const _PetCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
    required this.onViewMedicalHistory,
    this.onAddDocument,
    this.onAddVaccination,
    this.documents = const [],
    this.vaccinations = const [],
  });

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
                _PetAvatar(photoPath: pet.photoPath, name: pet.name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${pet.species} ${pet.breed ?? ''}'),
                      if (pet.dob != null) Text('Born: ${pet.dob}'),
                      if (pet.medicalHistorySummary != null &&
                          pet.medicalHistorySummary!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            pet.medicalHistorySummary!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      if ((pet.vaccinationStatus?['status'] as String?) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Chip(
                            label: Text(
                              'Vaccination: ${pet.vaccinationStatus!['status']}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'medical':
                        onViewMedicalHistory();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'medical',
                      child: Text('Medical History'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (pet.notes != null && pet.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${pet.notes}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Vaccination Records',
              actionLabel: 'Add',
              onAction: onAddVaccination,
            ),
            if (vaccinations.isEmpty)
              Text(
                'No vaccination records yet',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              )
            else
              ...vaccinations.take(3).map(
                    (record) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.vaccines, size: 20),
                      title: Text(record.vaccineName),
                      subtitle: Text(
                        'Given: ${record.vaccinationDate.toIso8601String().split('T').first}' +
                            (record.nextDueDate != null
                                ? '\nNext due: ${record.nextDueDate!.toIso8601String().split('T').first}'
                                : ''),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Documents & Images',
              actionLabel: 'Upload',
              onAction: onAddDocument,
            ),
            if (documents.isEmpty)
              Text(
                'No documents uploaded',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              )
            else
              ...documents.take(3).map(
                    (doc) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        doc.fileType == 'image'
                            ? Icons.image
                            : Icons.description,
                      ),
                      title: Text(doc.fileName),
                      subtitle: Text(
                        doc.description ?? doc.fileType,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onViewMedicalHistory,
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('View full medical history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
      ],
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final String? photoPath;
  final String name;

  const _PetAvatar({required this.photoPath, required this.name});

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty && !kIsWeb) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 30,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AddDocumentSheet extends StatefulWidget {
  final int petId;

  const _AddDocumentSheet({required this.petId});

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  String? _filePath;
  String? _fileName;
  String? _fileType;
  final _descriptionController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload document',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Choose file'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isUploading || _filePath == null ? null : _uploadDocument,
                child: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save document'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected file is not accessible on this platform'),
          ),
        );
      }
      return;
    }
    setState(() {
      _filePath = file.path;
      _fileName = file.name;
      _fileType = _resolveFileType(file.extension ?? '');
    });
  }

  Future<void> _uploadDocument() async {
    if (_filePath == null || _fileName == null) return;
    setState(() => _isUploading = true);
    final doc = Document(
      petId: widget.petId,
      fileName: _fileName!,
      fileType: _fileType ?? 'document',
      filePath: _filePath!,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      uploadDate: DateTime.now(),
    );
    final success =
        await context.read<PetProvider>().addDocument(doc);
    setState(() => _isUploading = false);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document saved successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save document')),
      );
    }
  }

  String _resolveFileType(String extension) {
    final lower = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'heic'].contains(lower)) {
      return 'image';
    }
    if (['pdf'].contains(lower)) {
      return 'pdf';
    }
    return 'document';
  }
}

class _AddVaccinationRecordDialog extends StatefulWidget {
  final int petId;

  const _AddVaccinationRecordDialog({required this.petId});

  @override
  State<_AddVaccinationRecordDialog> createState() =>
      _AddVaccinationRecordDialogState();
}

class _AddVaccinationRecordDialogState
    extends State<_AddVaccinationRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineController = TextEditingController();
  DateTime _vaccinationDate = DateTime.now();
  DateTime? _nextDueDate;
  final _batchController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _vaccineController.dispose();
    _batchController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
                controller: _vaccineController,
                decoration: const InputDecoration(labelText: 'Vaccine name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vaccination date'),
                subtitle: Text(
                  _vaccinationDate.toIso8601String().split('T').first,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _vaccinationDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _vaccinationDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next due date (optional)'),
                subtitle: Text(
                  _nextDueDate == null
                      ? 'Not set'
                      : _nextDueDate!.toIso8601String().split('T').first,
                ),
                trailing: const Icon(Icons.event_available),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _nextDueDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _nextDueDate = picked);
                  }
                },
              ),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch number (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vetController,
                decoration: const InputDecoration(
                  labelText: 'Veterinarian (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveRecord,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveRecord() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final record = VaccinationRecord(
      petId: widget.petId,
      vaccineName: _vaccineController.text,
      vaccinationDate: _vaccinationDate,
      nextDueDate: _nextDueDate,
      batchNumber: _batchController.text.isEmpty
          ? null
          : _batchController.text,
      veterinarianName: _vetController.text.isEmpty
          ? null
          : _vetController.text,
      notes:
          _notesController.text.isEmpty ? null : _notesController.text,
    );
    final success =
        await context.read<PetProvider>().addVaccinationRecord(record);
    setState(() => _saving = false);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaccination record added')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save record')),
      );
    }
  }
}

class _AddEditPetDialog extends StatefulWidget {
  final Pet? pet;

  const _AddEditPetDialog({this.pet});

  @override
  State<_AddEditPetDialog> createState() => _AddEditPetDialogState();
}

class _AddEditPetDialogState extends State<_AddEditPetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _dobController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicalSummaryController = TextEditingController();
  String _vaccinationStatus = 'Up to date';
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _speciesController.text = widget.pet!.species;
      _breedController.text = widget.pet!.breed ?? '';
      _dobController.text = widget.pet!.dob ?? '';
      _notesController.text = widget.pet!.notes ?? '';
      _medicalSummaryController.text =
          widget.pet!.medicalHistorySummary ?? '';
      final status = widget.pet!.vaccinationStatus?['status'] as String?;
      if (status != null && status.isNotEmpty) {
        _vaccinationStatus = status;
      }
      _photoPath = widget.pet!.photoPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    return AlertDialog(
      title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _speciesController.text.isEmpty
                    ? null
                    : _speciesController.text,
                decoration: const InputDecoration(labelText: 'Species'),
                items: const [
                  DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                  DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                  DropdownMenuItem(value: 'Bird', child: Text('Bird')),
                  DropdownMenuItem(value: 'Rabbit', child: Text('Rabbit')),
                  DropdownMenuItem(value: 'Hamster', child: Text('Hamster')),
                  DropdownMenuItem(value: 'Fish', child: Text('Fish')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _speciesController.text = value ?? '';
                  });
                },
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please select species' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Pet Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter pet name' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed (Optional)',
                ),
              ),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dobController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicalSummaryController,
                decoration: const InputDecoration(
                  labelText: 'Medical history summary',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _vaccinationStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'Up to date',
                    child: Text('Vaccinations up to date'),
                  ),
                  DropdownMenuItem(
                    value: 'Due soon',
                    child: Text('Vaccinations due soon'),
                  ),
                  DropdownMenuItem(
                    value: 'Overdue',
                    child: Text('Vaccinations overdue'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _vaccinationStatus = value ?? _vaccinationStatus);
                },
                decoration: const InputDecoration(
                  labelText: 'Vaccination status',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(_photoPath == null
                      ? 'Attach profile photo'
                      : 'Change photo'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              if (user == null || user.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not authenticated')),
                );
                return;
              }

              final pet = Pet(
                id: widget.pet?.id,
                ownerId: user.id!,
                name: _nameController.text,
                species: _speciesController.text,
                breed: _breedController.text.isEmpty
                    ? null
                    : _breedController.text,
                dob: _dobController.text.isEmpty ? null : _dobController.text,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
                medicalHistorySummary:
                    _medicalSummaryController.text.isEmpty
                        ? null
                        : _medicalSummaryController.text,
                vaccinationStatus: {
                  'status': _vaccinationStatus,
                  'updatedAt': DateTime.now().toIso8601String(),
                },
                photoPath: _photoPath,
              );

              final success = widget.pet == null
                  ? await context.read<PetProvider>().addPet(pet)
                  : await context.read<PetProvider>().updatePet(pet);

              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.pet == null
                          ? 'Pet added successfully'
                          : 'Pet updated successfully',
                    ),
                  ),
                );
              }
            }
          },
          child: Text(widget.pet == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _dobController.dispose();
    _notesController.dispose();
    _medicalSummaryController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access selected image on this platform'),
          ),
        );
      }
      return;
    }
    setState(() => _photoPath = file.path);
  }
}

class MedicalHistoryScreen extends StatefulWidget {
  final Pet pet;

  const MedicalHistoryScreen({super.key, required this.pet});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final petProvider = context.read<PetProvider>();
    if (widget.pet.id == null) {
      setState(() => _isLoading = false);
      return;
    }
    await Future.wait([
      petProvider.loadMedicalRecords(widget.pet.id!),
      petProvider.loadDocuments(widget.pet.id!),
      petProvider.loadVaccinationRecords(widget.pet.id!),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final records = widget.pet.id == null
        ? <MedicalRecord>[]
        : petProvider.getMedicalRecordsByPet(widget.pet.id!);
    final documents = widget.pet.id == null
        ? <Document>[]
        : petProvider.getDocumentsByPet(widget.pet.id!);
    final vaccinations = widget.pet.id == null
        ? <VaccinationRecord>[]
        : petProvider.getVaccinationRecordsForPet(widget.pet.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pet.name} - Medical History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Records'),
            Tab(text: 'Documents'),
            Tab(text: 'Vaccinations'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF summary',
            onPressed: _isLoading ? null : _downloadPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _MedicalRecordTab(records: records),
                _DocumentTab(documents: documents),
                _VaccinationTab(records: vaccinations),
              ],
            ),
    );
  }

  Future<void> _downloadPdf() async {
    final petProvider = context.read<PetProvider>();
    final records = widget.pet.id == null
        ? <MedicalRecord>[]
        : petProvider.getMedicalRecordsByPet(widget.pet.id!);
    final documents = widget.pet.id == null
        ? <Document>[]
        : petProvider.getDocumentsByPet(widget.pet.id!);
    final vaccinations = widget.pet.id == null
        ? <VaccinationRecord>[]
        : petProvider.getVaccinationRecordsForPet(widget.pet.id!);

    final pdf = pw.Document();
    final formatter = DateFormat('yyyy-MM-dd');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('${widget.pet.name} Medical History',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 8),
          pw.Text('Species: ${widget.pet.species}'),
          if (widget.pet.breed != null) pw.Text('Breed: ${widget.pet.breed}'),
          if (widget.pet.dob != null) pw.Text('DOB: ${widget.pet.dob}'),
          if (widget.pet.medicalHistorySummary != null)
            pw.Text('Summary: ${widget.pet.medicalHistorySummary}'),
          pw.SizedBox(height: 16),
          pw.Text('Medical Records',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (records.isEmpty)
            pw.Text('No medical records found')
          else
            ...records.map(
              (record) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date: ${formatter.format(DateTime.parse(record.date))}'),
                  pw.Text('Diagnosis: ${record.diagnosis}'),
                  pw.Text('Treatment: ${record.treatment}'),
                  if (record.prescription != null)
                    pw.Text('Prescription: ${record.prescription}'),
                  if (record.notes != null)
                    pw.Text('Notes: ${record.notes}'),
                  pw.SizedBox(height: 8),
                ],
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text('Documents',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (documents.isEmpty)
            pw.Text('No documents uploaded')
          else
            ...documents.map(
              (doc) => pw.Text(
                '${doc.fileName} (${doc.fileType}) - ${formatter.format(doc.uploadDate)}',
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text('Vaccination Records',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (vaccinations.isEmpty)
            pw.Text('No vaccination history')
          else
            ...vaccinations.map(
              (record) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${record.vaccineName} - ${formatter.format(record.vaccinationDate)}',
                  ),
                  if (record.nextDueDate != null)
                    pw.Text('Next due: ${formatter.format(record.nextDueDate!)}'),
                  if (record.notes != null) pw.Text('Notes: ${record.notes}'),
                  pw.SizedBox(height: 6),
                ],
              ),
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${widget.pet.name.toLowerCase()}_medical_history.pdf',
    );
  }
}

class _MedicalRecordTab extends StatelessWidget {
  final List<MedicalRecord> records;

  const _MedicalRecordTab({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No medical records yet'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final recordDate = DateTime.tryParse(record.date);
        final formattedDate =
            recordDate != null ? DateFormat('yMMMd').format(recordDate) : record.date;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Diagnosis: ${record.diagnosis}'),
                Text('Treatment: ${record.treatment}'),
                if (record.prescription != null)
                  Text('Prescription: ${record.prescription}'),
                if (record.notes != null) Text('Notes: ${record.notes}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DocumentTab extends StatelessWidget {
  final List<Document> documents;

  const _DocumentTab({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No documents uploaded'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return ListTile(
          leading: Icon(
            document.fileType == 'image' ? Icons.image : Icons.description,
          ),
          title: Text(document.fileName),
          subtitle: Text(
            document.description ?? document.fileType,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(DateFormat('yMMMd').format(document.uploadDate)),
        );
      },
    );
  }
}

class _VaccinationTab extends StatelessWidget {
  final List<VaccinationRecord> records;

  const _VaccinationTab({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('No vaccination records'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final dueDate = record.nextDueDate != null
            ? DateFormat('yMMMd').format(record.nextDueDate!)
            : 'Not scheduled';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.vaccines),
            title: Text(record.vaccineName),
            subtitle: Text(
              'Given: ${DateFormat('yMMMd').format(record.vaccinationDate)}\nNext due: $dueDate',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

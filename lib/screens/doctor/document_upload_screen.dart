// lib/screens/doctor/document_upload_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added import for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/document_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pet.dart';
import '../../models/medical_record.dart';
import '../../components/modern_cards.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  Pet? _selectedPet;
  MedicalRecord? _selectedMedicalRecord;
  File? _selectedFile;
  String? _fileName;
  List<int>? _fileBytes; // For web fallback
  final TextEditingController _descriptionController = TextEditingController();
  String _accessLevel = 'private';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Timer? _progressTimer;

  final List<String> _accessLevels = ['private', 'public', 'restricted'];

  @override
  void initState() {
    super.initState();
    // Check if we have a pet from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map?;
      if (arguments != null && arguments.containsKey('pet')) {
        _onPetSelected(arguments['pet'] as Pet?);
      }

      // Load pets based on user role
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user != null && user.role == 'doctor' && user.id != null) {
        context.read<PetProvider>().loadPetsByDoctor(user.id!);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _onPetSelected(Pet? pet) {
    setState(() {
      _selectedPet = pet;
      _selectedMedicalRecord = null; // Reset medical record selection
    });
    if (pet != null) {
      context.read<MedicalProvider>().loadMedicalRecordsByPet(pet.id!);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
        allowMultiple: false,
        withData: true, // Ensure bytes are available on web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Handle different platforms
        File? selectedFile;
        if (kIsWeb) {
          // Web: do not create File from path or bytes, just store bytes
          selectedFile = null;
        } else if (file.path != null) {
          // Mobile/Desktop: path is available
          selectedFile = File(file.path!);
        }

        setState(() {
          _selectedFile = selectedFile;
          _fileName = file.name;
          _fileBytes = file.bytes; // Store bytes as fallback
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a pet')));
      return;
    }

    if (_fileBytes == null && _selectedFile == null) {
      // Adjusted to check both
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate progress faster
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _uploadProgress += 0.04;
          if (_uploadProgress >= 1.0) {
            timer.cancel();
            _progressTimer = null;
          }
        });
      } else {
        timer.cancel();
        _progressTimer = null;
      }
    });

    try {
      final documentProvider = Provider.of<DocumentProvider>(
        context,
        listen: false,
      );
      final document = await documentProvider.uploadDocument(
        petId: _selectedPet!.id!,
        fileName: _fileName!,
        file: kIsWeb ? null : _selectedFile,
        fileBytes: kIsWeb ? _fileBytes : null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        accessLevel: _accessLevel,
        medicalRecordId: _selectedMedicalRecord?.id,
      );

      _progressTimer?.cancel();
      _progressTimer = null;
      if (mounted) {
        setState(() => _uploadProgress = 1.0);
      }

      if (document != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        // Reset form
        setState(() {
          _selectedFile = null;
          _fileName = null;
          _descriptionController.clear();
          _selectedPet = null;
          _uploadProgress = 0.0;
          _fileBytes = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document')),
        );
      }
    } catch (e) {
      _progressTimer?.cancel();
      _progressTimer = null;
      if (mounted) {
        setState(() => _uploadProgress = 0.0);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading document: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medical Document'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedCard(0, _buildPetSelection()),
            const SizedBox(height: 16),
            _buildAnimatedCard(1, _buildMedicalRecordSelection()),
            const SizedBox(height: 16),
            _buildAnimatedCard(2, _buildFileSelection()),
            const SizedBox(height: 16),
            _buildAnimatedCard(3, _buildDescription()),
            const SizedBox(height: 16),
            _buildAnimatedCard(3, _buildAccessLevel()),
            const SizedBox(height: 16),
            if (_isUploading) ...[
              ModernProgressCard(
                title: 'Uploading Document',
                subtitle: 'Please wait while we upload your file...',
                progress: _uploadProgress,
                color: Theme.of(context).primaryColor,
                icon: Icons.cloud_upload,
              ),
              const SizedBox(height: 24),
            ],
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordSelection() {
    return Consumer<MedicalProvider>(
      builder: (context, medicalProvider, child) {
        // Get medical records for the selected pet
        List<MedicalRecord> availableRecords = [];
        if (_selectedPet != null) {
          availableRecords = medicalProvider
              .getMedicalRecordsByPet(_selectedPet!.id!)
              .toSet()
              .toList(); // Ensure unique records
        }

        // Reset selected medical record if it's not in available records
        if (_selectedMedicalRecord != null &&
            !availableRecords.contains(_selectedMedicalRecord)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedMedicalRecord = null);
          });
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link to Medical Record (Optional)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Associate this document with a specific medical record',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MedicalRecord?>(
                  value: _selectedMedicalRecord,
                  hint: const Text('Select a medical record (optional)'),
                  items: [
                    const DropdownMenuItem<MedicalRecord?>(
                      value: null,
                      child: Text('No specific record'),
                    ),
                    ...availableRecords.map((record) {
                      return DropdownMenuItem<MedicalRecord>(
                        value: record,
                        child: Text(
                          record.diagnosis.length > 30
                              ? '${record.diagnosis.substring(0, 30)}...'
                              : record.diagnosis,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (record) {
                    setState(() => _selectedMedicalRecord = record);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                if (_selectedPet == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select a pet first to view available medical records',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, childWidget) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(opacity: animationValue, child: childWidget),
        );
      },
      child: child,
    );
  }

  Widget _buildPetSelection() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        if (petProvider.pets.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No pets available. Please add pets first.'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Pet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Pet>(
                  initialValue: _selectedPet,
                  hint: const Text('Choose a pet'),
                  items: petProvider.pets.map((pet) {
                    return DropdownMenuItem<Pet>(
                      value: pet,
                      child: Text('${pet.name} (${pet.species})'),
                    );
                  }).toList(),
                  onChanged: _onPetSelected,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileSelection() {
    return Card(
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _fileName != null
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 2,
              style: _fileName != null ? BorderStyle.solid : BorderStyle.none,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _fileName != null
                    ? Icons.insert_drive_file
                    : Icons.cloud_upload,
                size: 48,
                color: _fileName != null
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                _fileName ?? 'Tap to select a file',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _fileName != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                  color: _fileName != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supported: PDF, JPG, PNG, DOC, DOCX, TXT (Max 10MB)',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter document description...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessLevel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Access Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _accessLevel,
              items: _accessLevels.map((level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level.toUpperCase()),
                );
              }).toList(),
              onChanged: (level) {
                setState(() => _accessLevel = level!);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Private: Only pet owner and uploader\nPublic: Anyone can view\nRestricted: Only doctors and admins',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _selectedPet != null &&
                  (_selectedFile != null || _fileBytes != null) &&
                  !_isUploading
              ? [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ]
              : [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            _selectedPet != null &&
                (_selectedFile != null || _fileBytes != null) &&
                !_isUploading
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed:
            (_selectedPet != null &&
                (_selectedFile != null || _fileBytes != null) &&
                !_isUploading)
            ? _uploadDocument
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          _selectedPet != null &&
                              (_selectedFile != null || _fileBytes != null)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

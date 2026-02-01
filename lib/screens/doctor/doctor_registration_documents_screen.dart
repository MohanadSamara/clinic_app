// lib/screens/doctor/doctor_registration_documents_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../../translations.dart';
import '../role_based_home.dart';

class DoctorRegistrationDocumentsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String area;

  const DoctorRegistrationDocumentsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    required this.area,
  });

  @override
  State<DoctorRegistrationDocumentsScreen> createState() =>
      _DoctorRegistrationDocumentsScreenState();
}

class _DoctorRegistrationDocumentsScreenState
    extends State<DoctorRegistrationDocumentsScreen> {
  // Simplified document requirements - only 2 required documents
  final List<Map<String, dynamic>> _documentRequirements = [
    {
      'type': 'license',
      'title': 'Veterinary License',
      'description': 'Upload your official veterinary license',
      'required': false,
      'allowedExtensions': ['pdf', 'jpg', 'jpeg', 'png'],
    },
    {
      'type': 'id',
      'title': 'Government ID',
      'description': 'Upload your national ID or passport',
      'required': false,
      'allowedExtensions': ['pdf', 'jpg', 'jpeg', 'png'],
    },
  ];

  final List<Map<String, dynamic>> _documents = [];
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
  }

  void _initializeDocuments() {
    for (final requirement in _documentRequirements) {
      _documents.add({
        'requirement': requirement,
        'file': null,
        'fileName': null,
        'fileBytes': null,
        'document_type': requirement['type'],
        'documentNumber': '',
        'expiryDate': null,
        'issuingAuthority': '',
        'verificationCode': '',
        'file_path': null,
        'file_data': null,
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions:
            _documentRequirements[index]['allowedExtensions'] as List<String>,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        File? selectedFile;
        if (kIsWeb) {
          selectedFile = null;
        } else if (file.path != null) {
          selectedFile = File(file.path!);
        }

        setState(() {
          _documents[index]['file'] = selectedFile;
          _documents[index]['fileName'] = file.name;
          _documents[index]['fileBytes'] = file.bytes;
          _documents[index]['file_path'] = kIsWeb ? null : selectedFile?.path;
          _documents[index]['file_data'] = kIsWeb ? file.bytes : null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('errorPickingFile')}: $e')),
      );
    }
  }

  bool _isFormValid() {
    for (final doc in _documents) {
      if ((doc['requirement']['required'] == true) &&
          (doc['file'] == null && doc['fileBytes'] == null)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitDocuments() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Store documents data temporarily (without saving user to database)
      final documentsData = <String, dynamic>{};
      for (int i = 0; i < _documents.length; i++) {
        final doc = _documents[i];
        if (doc['file'] != null || doc['fileBytes'] != null) {
          documentsData[doc['document_type'] as String] = {
            'document_type': doc['document_type'],
            'fileName': doc['fileName'],
            'file_path': doc['file_path'],
            'file_data': doc['file_data'],
            'documentNumber': doc['documentNumber'],
            'expiry_date': doc['expiryDate']?.toIso8601String(),
            'issuingAuthority': doc['issuingAuthority'],
            'verificationCode': doc['verificationCode'],
          };
        }
      }

      // Update pending registration with documents (using unified method)
      await authProvider.storePendingRegistration(
        name: widget.name,
        email: widget.email,
        password: widget.password,
        phone: widget.phone,
        role: 'doctor',
        area: widget.area,
        documents: documentsData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Documents uploaded successfully! Completing registration...',
            ),
          ),
        );

        // Complete registration using unified method
        await authProvider.completeRegistration();

        if (mounted) {
          // Navigate to doctor home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleBasedHome()),
          );
        }

        if (mounted) {
          // Navigate to doctor home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleBasedHome()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during registration: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildDocumentCard(int index) {
    final doc = _documents[index];
    final requirement = doc['requirement'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    requirement['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (requirement['required'] == true)
                  Text(
                    '*',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              requirement['description'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickFile(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: doc['fileName'] != null
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      doc['fileName'] != null
                          ? Icons.check_circle
                          : Icons.cloud_upload,
                      color: doc['fileName'] != null
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['fileName'] ?? 'Tap to select file',
                        style: TextStyle(
                          color: doc['fileName'] != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (doc['fileName'] != null)
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simple Verification Process',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your license and ID to complete registration. '
                      'Your account will be verified automatically.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document list
            ..._documents.asMap().entries.map((entry) {
              return _buildDocumentCard(entry.key);
            }),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting || !_isFormValid()
                    ? null
                    : _submitDocuments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Complete Registration'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

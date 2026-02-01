// lib/screens/driver/driver_verification_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_complete_service.dart';
import '../../../translations.dart';
import '../role_based_home.dart';

class DriverVerificationScreen extends StatefulWidget {
  final String? email;
  final bool isPreLogin;

  const DriverVerificationScreen({
    super.key,
    this.email,
    this.isPreLogin = false,
  });

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final List<Map<String, dynamic>> _documentRequirements = [
    {
      'type': 'driving_license',
      'title': 'Driving License',
      'description': 'Upload your valid driving license',
      'required': false,
      'helpText':
          'Must be current and valid. Include license number and expiry date.',
    },
    {
      'type': 'id_card',
      'title': 'National ID Card',
      'description': 'Upload your national ID or passport',
      'required': false,
      'helpText': 'Must be clear and readable.',
    },
    {
      'type': 'vehicle_insurance',
      'title': 'Vehicle Insurance',
      'description': 'Upload your vehicle insurance certificate',
      'required': false,
      'helpText': 'Must be current and include coverage details.',
    },
  ];

  // Driving license number patterns for different countries
  final Map<String, RegExp> _licensePatterns = {
    'jordan': RegExp(r'^[A-Z]{1,2}\d{5,8}$'),
    'generic': RegExp(r'^[A-Z0-9]{6,15}$'),
  };

  // Common issuing authorities
  final List<String> _issuingAuthorities = [
    'Ministry of Transportation',
    'Department of Motor Vehicles',
    'Driver and Vehicle Licensing Agency',
    'Transport Authority',
    'Road Transport Authority',
    'Other',
  ];

  // Vehicle class options for driving license
  final List<String> _vehicleClasses = [
    'A - Motorcycle',
    'B - Car',
    'C - Truck',
    'D - Bus',
    'B1 - Three-wheeler',
    'C1 - Light Truck',
    'D1 - Minibus',
    'M - Moped',
    'Professional - Commercial',
  ];

  final List<Map<String, dynamic>> _documents = [];
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _existingDocuments = [];
  String _overallStatus = 'pending';
  int _approvedCount = 0;
  int _pendingCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
    _loadExistingDocuments();
  }

  void _initializeDocuments() {
    for (final requirement in _documentRequirements) {
      _documents.add({
        'requirement': requirement,
        'file': null,
        'fileName': null,
        'fileBytes': null,
        'documentNumber': '',
        'expiryDate': null,
        'issueDate': null,
        'issuingAuthority': '',
        'verificationCode': '',
        'vehicleClass': '',
        'licenseFront': null,
        'licenseBack': null,
      });
    }
  }

  Future<void> _loadExistingDocuments() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (widget.isPreLogin && widget.email != null) {
      // Load documents by email for pre-login flow
      final supabaseService = SupabaseCompleteService.instance;
      final docs = await supabaseService.getDriverVerificationDocumentsByEmail(
        widget.email!,
      );
      setState(() {
        _existingDocuments = docs;
        _calculateStatus();
        _isLoading = false;
      });
    } else if (user != null && user.id != null) {
      final supabaseService = SupabaseCompleteService.instance;
      final docs = await supabaseService.getDriverVerificationDocuments(
        user.id!,
      );
      setState(() {
        _existingDocuments = docs;
        _calculateStatus();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStatus() {
    _approvedCount = 0;
    _pendingCount = 0;
    _rejectedCount = 0;

    for (final doc in _existingDocuments) {
      final status = doc['status'] as String? ?? 'pending';
      switch (status) {
        case 'approved':
          _approvedCount++;
          break;
        case 'rejected':
          _rejectedCount++;
          break;
        default:
          _pendingCount++;
          break;
      }
    }

    // Determine overall status
    if (_rejectedCount > 0) {
      _overallStatus = 'rejected';
    } else if (_pendingCount > 0) {
      _overallStatus = 'pending';
    } else if (_approvedCount > 0) {
      _overallStatus = 'approved';
    } else {
      _overallStatus = 'pending';
    }
  }

  Future<void> _pickFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  bool _isFormValid() {
    for (final doc in _documents) {
      final requirement = doc['requirement'] as Map<String, dynamic>;
      if ((requirement['required'] == true) &&
          (doc['file'] == null && doc['fileBytes'] == null)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitVerification() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (widget.isPreLogin) {
      // For pre-login registration, store documents and complete registration using unified flow
      try {
        final authProvider = context.read<AuthProvider>();

        // Prepare documents data
        final documentsData = <String, dynamic>{};
        for (int i = 0; i < _documents.length; i++) {
          final doc = _documents[i];
          if (doc['file'] != null || doc['fileBytes'] != null) {
            final requirement = doc['requirement'] as Map<String, dynamic>;

            // Parse dates
            String? expiryDateStr;
            if (doc['expiryDate'] != null) {
              expiryDateStr = (doc['expiryDate'] as DateTime).toIso8601String();
            }
            String? issueDateStr;
            if (doc['issueDate'] != null) {
              issueDateStr = (doc['issueDate'] as DateTime).toIso8601String();
            }

            documentsData[requirement['type']] = {
              'document_type': requirement['type'],
              'fileName': doc['fileName'],
              'file_path': kIsWeb ? null : (doc['file'] as File?)?.path,
              'file_data': kIsWeb ? doc['fileBytes'] : null,
              'documentNumber': doc['documentNumber'] ?? '',
              'expiry_date': expiryDateStr,
              'issue_date': issueDateStr,
              'issuingAuthority': doc['issuingAuthority'] ?? '',
              'verificationCode': doc['verificationCode'] ?? '',
              'vehicleClass': doc['vehicleClass'] ?? '',
            };
          }
        }

        // Get pending registration data
        final pendingReg = authProvider.pendingRegistration;
        if (pendingReg == null) {
          throw Exception('No pending registration found');
        }

        // Update pending registration with documents using unified method
        await authProvider.storePendingRegistration(
          name: pendingReg['name'],
          email: pendingReg['email'],
          password: pendingReg['password'],
          phone: pendingReg['phone'],
          role: 'driver',
          area: pendingReg['area'],
          documents: documentsData,
        );

        // Complete registration using unified method
        await authProvider.completeRegistration();

        if (mounted) {
          // Navigate to driver home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleBasedHome()),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration completed successfully!'),
            ),
          );
          // Navigate to driver home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleBasedHome()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during registration: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null || user.id == null) {
        throw Exception('User not found');
      }

      // Upload each document
      for (final doc in _documents) {
        if (doc['file'] != null || doc['fileBytes'] != null) {
          final requirement = doc['requirement'] as Map<String, dynamic>;

          // Parse expiry date
          String? expiryDateStr;
          if (doc['expiryDate'] != null) {
            expiryDateStr = (doc['expiryDate'] as DateTime).toIso8601String();
          }

          // Parse issue date
          String? issueDateStr;
          if (doc['issueDate'] != null) {
            issueDateStr = (doc['issueDate'] as DateTime).toIso8601String();
          }

          final documentData = {
            'driver_id': user.id,
            'document_type': requirement['type'],
            'file_name': doc['fileName'],
            'file_path': kIsWeb ? null : (doc['file'] as File?)?.path,
            'file_data': kIsWeb ? doc['fileBytes'] : null,
            'upload_date': DateTime.now().toIso8601String(),
            'status': 'pending',
            'document_number': doc['documentNumber'] ?? '',
            'expiry_date': expiryDateStr,
            'issue_date': issueDateStr,
            'issuing_authority': doc['issuingAuthority'] ?? '',
            'verification_code': doc['verificationCode'] ?? '',
            'vehicle_class': doc['vehicleClass'] ?? '',
          };

          await SupabaseCompleteService.instance
              .insertDriverVerificationDocument(documentData);
        }
      }

      // Update user verification status
      await authProvider.updateVerificationStatus('pending');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification documents submitted successfully'),
          ),
        );
        // Navigate to role-based home and then to driver dashboard
        Navigator.of(context).pushReplacementNamed('/role-based-home');
      }
    } catch (e) {
      debugPrint('Error submitting verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting verification: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
        title: Text(context.tr('driverVerification')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadExistingDocuments,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 16),

              // Existing Documents
              if (_existingDocuments.isNotEmpty) ...[
                _buildExistingDocumentsList(),
                const SizedBox(height: 16),
              ],

              // New Document Upload
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Documents',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your driving license and other required documents for verification.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ..._documents.asMap().entries.map((entry) {
                        return _buildDocumentCard(entry.key);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_isFormValid()
                      ? null
                      : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : Text(context.tr('submitForVerification')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _getStatusColor(_overallStatus).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(_overallStatus),
                  color: _getStatusColor(_overallStatus),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Verification Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_overallStatus),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(_overallStatus),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(_overallStatus),
              ),
            ),
            const SizedBox(height: 12),
            if (_overallStatus == 'pending')
              Text(
                'Your documents are currently under review by our admin team. You will be notified once the verification is complete.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_overallStatus == 'approved')
              Text(
                'Congratulations! Your verification is complete. You can now access all driver features.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_overallStatus == 'rejected')
              Text(
                'Some of your documents were rejected. Please review the feedback and resubmit the required documents.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem('Approved', _approvedCount, Colors.green),
                _buildStatusItem('Pending', _pendingCount, Colors.orange),
                _buildStatusItem('Rejected', _rejectedCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildExistingDocumentsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Existing Documents',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _existingDocuments.length,
              itemBuilder: (context, index) {
                final doc = _existingDocuments[index];
                final status = doc['status'] as String? ?? 'pending';
                final documentType =
                    doc['document_type'] as String? ?? 'Unknown';
                final fileName = doc['file_name'] as String? ?? 'Unknown';
                final uploadDate = doc['upload_date'] as String? ?? '';
                final reviewNotes = doc['review_notes'] as String? ?? '';

                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                      ),
                      title: Text(
                        _getDocumentTitle(documentType),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Uploaded: ${_formatDate(uploadDate)}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (reviewNotes.isNotEmpty && status == 'rejected')
                            Text(
                              'Feedback: $reviewNotes',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (index < _existingDocuments.length - 1)
                      Divider(
                        color: Theme.of(context).colorScheme.outline,
                        height: 1,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(int index) {
    final doc = _documents[index];
    final requirement = doc['requirement'] as Map<String, dynamic>;
    final isDrivingLicense = requirement['type'] == 'driving_license';

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
                    requirement['title'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (requirement['required'])
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
              requirement['description'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (requirement['helpText'] != null) ...[
              const SizedBox(height: 8),
              Text(
                requirement['helpText'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
                          ? Icons.insert_drive_file
                          : Icons.cloud_upload,
                      color: doc['fileName'] != null
                          ? Theme.of(context).primaryColor
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Additional fields for document details
            TextField(
              decoration: InputDecoration(
                labelText: isDrivingLicense
                    ? 'License Number'
                    : 'Document Number',
                hintText: isDrivingLicense ? 'e.g., A12345' : 'e.g., ID12345',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  doc['documentNumber'] = value;
                });
              },
            ),
            const SizedBox(height: 8),
            // Driving License specific fields
            if (isDrivingLicense) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Vehicle Class',
                  border: OutlineInputBorder(),
                ),
                value: doc['vehicleClass'].isEmpty ? null : doc['vehicleClass'],
                items: _vehicleClasses.map((classItem) {
                  return DropdownMenuItem<String>(
                    value: classItem.split(' - ')[0],
                    child: Text(classItem),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    doc['vehicleClass'] = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              decoration: InputDecoration(
                labelText: 'Issuing Authority',
                hintText: 'e.g., Ministry of Transportation',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  doc['issuingAuthority'] = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Verification Code (if applicable)',
                hintText: 'e.g., Online verification code',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  doc['verificationCode'] = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Issue Date',
                      hintText: 'YYYY-MM-DD',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty) {
                          try {
                            doc['issueDate'] = DateTime.parse(value);
                          } catch (e) {
                            doc['issueDate'] = null;
                          }
                        } else {
                          doc['issueDate'] = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'YYYY-MM-DD',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty) {
                          try {
                            doc['expiryDate'] = DateTime.parse(value);
                          } catch (e) {
                            doc['expiryDate'] = null;
                          }
                        } else {
                          doc['expiryDate'] = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Verified';
      case 'rejected':
        return 'Verification Failed';
      case 'pending':
      default:
        return 'Under Review';
    }
  }

  String _getDocumentTitle(String type) {
    switch (type) {
      case 'driving_license':
        return 'Driving License';
      case 'id_card':
        return 'National ID Card';
      case 'vehicle_insurance':
        return 'Vehicle Insurance';
      default:
        return type;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}

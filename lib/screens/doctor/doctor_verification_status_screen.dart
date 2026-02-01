// lib/screens/doctor/doctor_verification_status_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_complete_service.dart';
import '../../models/doctor_verification.dart';
import 'doctor_verification_screen.dart';
import '../../../translations.dart';

class DoctorVerificationStatusScreen extends StatefulWidget {
  const DoctorVerificationStatusScreen({super.key});

  @override
  State<DoctorVerificationStatusScreen> createState() =>
      _DoctorVerificationStatusScreenState();
}

class _DoctorVerificationStatusScreenState
    extends State<DoctorVerificationStatusScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];
  String _overallStatus = 'pending';
  int _approvedCount = 0;
  int _pendingCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.id != null) {
      try {
        final supabaseService = SupabaseCompleteService.instance;
        final docs = await supabaseService.getDoctorVerificationDocuments(
          user.id!,
        );
        setState(() {
          _documents = docs;
          _calculateStatus();
          _isLoading = false;
        });

        // If all documents are approved, update user verification status
        if (_overallStatus == 'approved') {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          if (authProvider.user?.verificationStatus != 'verified') {
            await supabaseService.updateUser(user.id!, {
              'verification_status': 'verified',
            });
            // Update the user in provider
            final updatedUser = authProvider.user!.copyWith(
              verificationStatus: 'verified',
            );
            authProvider.updateUser(updatedUser);
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading verification status: $e')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatus() {
    _approvedCount = 0;
    _pendingCount = 0;
    _rejectedCount = 0;

    for (final doc in _documents) {
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
                'Congratulations! Your verification is complete. You can now access all doctor features.',
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

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.document_scanner,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No documents submitted yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete your registration by submitting the required documents.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to document upload screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorVerificationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Upload Documents'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submitted Documents',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
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
                    if (index < _documents.length - 1)
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

  String _getDocumentTitle(String type) {
    switch (type) {
      case 'license':
        return 'Veterinary License';
      case 'diploma':
        return 'Veterinary Degree/Diploma';
      case 'id':
        return 'Government ID';
      case 'certificate':
        return 'Additional Certifications';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('verificationStatus')),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadVerificationStatus,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildDocumentsList(),
                    const SizedBox(height: 16),
                    if (_overallStatus == 'rejected')
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to document upload screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DoctorVerificationScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Resubmit Documents'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Note: Verification typically takes 1-3 business days. You will receive a notification once your status changes.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

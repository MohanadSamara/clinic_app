// lib/screens/doctor/medical_record_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/medical_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medical_record.dart';
import '../../models/document.dart';
import '../../models/pet.dart';
import '../../db/db_helper.dart';
import '../../components/modern_cards.dart';

class MedicalRecordDetailScreen extends StatefulWidget {
  final MedicalRecord record;
  final Pet? pet;

  const MedicalRecordDetailScreen({super.key, required this.record, this.pet});

  @override
  State<MedicalRecordDetailScreen> createState() =>
      _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen> {
  bool _isLoading = false;
  List<Document> _relatedDocuments = [];
  Pet? _pet;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load pet information if not provided
      if (_pet == null) {
        final petData = await DBHelper.instance.getPetById(widget.record.petId);
        if (petData != null) {
          setState(() {
            _pet = Pet.fromMap(petData);
          });
        }
      }

      // Load related documents
      await _loadRelatedDocuments();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRelatedDocuments() async {
    try {
      final documentProvider = Provider.of<DocumentProvider>(
        context,
        listen: false,
      );
      await documentProvider.loadDocuments(medicalRecordId: widget.record.id);

      setState(() {
        _relatedDocuments = documentProvider.documents;
      });
    } catch (e) {
      debugPrint('Error loading documents: $e');
    }
  }

  Future<void> _downloadDocument(Document document) async {
    setState(() => _isLoading = true);

    try {
      final documentProvider = Provider.of<DocumentProvider>(
        context,
        listen: false,
      );
      final success = await documentProvider.downloadDocument(document);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document downloaded successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download document')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _previewDocument(Document document) async {
    // This would open a document preview (implementation depends on file type)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preview functionality for ${document.fileName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editRecord(),
          ),
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () => _addDocuments(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecordInfoCard(),
                  const SizedBox(height: 16),
                  _buildDocumentsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildRecordInfoCard() {
    final record = widget.record;
    final petName = _pet?.name ?? 'Unknown Pet';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Record',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pet: $petName',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              'Date',
              DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date)),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Doctor ID', record.doctorId.toString()),
            const SizedBox(height: 20),
            _buildSectionHeader('Diagnosis', Icons.medical_services),
            const SizedBox(height: 8),
            Text(
              record.diagnosis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Treatment', Icons.healing),
            const SizedBox(height: 8),
            Text(
              record.treatment,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (record.prescription != null) ...[
              const SizedBox(height: 20),
              _buildSectionHeader('Prescription', Icons.medication),
              const SizedBox(height: 8),
              Text(
                record.prescription!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (record.notes != null) ...[
              const SizedBox(height: 20),
              _buildSectionHeader('Notes', Icons.note),
              const SizedBox(height: 8),
              Text(record.notes!, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Related Documents (${_relatedDocuments.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addDocuments,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Files'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_relatedDocuments.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents attached',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload medical documents, lab results, or images related to this record',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addDocuments,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Documents'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _relatedDocuments.length,
                itemBuilder: (context, index) {
                  final document = _relatedDocuments[index];
                  return _buildDocumentTile(document);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(Document document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(document.fileType),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          document.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploaded: ${DateFormat('MMM dd, yyyy').format(document.uploadDate)}',
            ),
            if (document.description != null) Text(document.description!),
            Text('Size: ${(document.fileSize / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'preview':
                _previewDocument(document);
                break;
              case 'download':
                _downloadDocument(document);
                break;
              case 'delete':
                _deleteDocument(document);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'preview',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Preview'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _editRecord() {
    Navigator.of(context)
        .pushNamed(
          '/doctor/medical-record-form',
          arguments: {'record': widget.record, 'pet': _pet},
        )
        .then((_) => _loadData());
  }

  void _addDocuments() {
    Navigator.of(context)
        .pushNamed('/doctor/document-upload', arguments: {'pet': _pet})
        .then((_) => _loadRelatedDocuments());
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.fileName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final documentProvider = Provider.of<DocumentProvider>(
          context,
          listen: false,
        );
        final success = await documentProvider.deleteDocument(document.id!);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document deleted successfully')),
            );
            _loadRelatedDocuments();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete document')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting document: $e')),
          );
        }
      }
    }
  }
}

// lib/screens/owner/medical_documents_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/document.dart';
import '../../models/pet.dart';
import '../../theme/app_theme.dart';

class MedicalDocumentsScreen extends StatefulWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  State<MedicalDocumentsScreen> createState() => _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState extends State<MedicalDocumentsScreen> {
  Pet? _selectedPet;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  Future<void> _loadDocuments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );

    if (authProvider.isLoggedIn) {
      setState(() => _isLoading = true);
      await documentProvider.loadDocuments(userId: authProvider.user!.id!);
      setState(() => _isLoading = false);
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

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document downloaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download document')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading document: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewAuditLogs(Document document) async {
    final documentProvider = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );
    final auditLogs = await documentProvider.getAuditLogs(document.id!);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: auditLogs.length,
            itemBuilder: (context, index) {
              final log = auditLogs[index];
              return ListTile(
                title: Text(log.action.toUpperCase()),
                subtitle: Text(
                  '${DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp)}\n'
                  'User ID: ${log.userId}',
                ),
                trailing: log.details != null ? Text(log.details!) : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Documents'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pet Filter
          Consumer<PetProvider>(
            builder: (context, petProvider, child) {
              if (petProvider.pets.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: DropdownButtonFormField<Pet?>(
                  value: _selectedPet,
                  hint: const Text('Filter by pet (optional)'),
                  items: [
                    const DropdownMenuItem<Pet?>(
                      value: null,
                      child: Text('All pets'),
                    ),
                    ...petProvider.pets.map((pet) {
                      return DropdownMenuItem<Pet?>(
                        value: pet,
                        child: Text('${pet.name} (${pet.species})'),
                      );
                    }),
                  ],
                  onChanged: (pet) {
                    setState(() => _selectedPet = pet);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              );
            },
          ),

          // Documents List
          Expanded(
            child: Consumer<DocumentProvider>(
              builder: (context, documentProvider, child) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var documents = documentProvider.documents;

                // Filter by selected pet
                if (_selectedPet != null) {
                  documents = documents
                      .where((doc) => doc.petId == _selectedPet!.id)
                      .toList();
                }

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No medical documents found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Documents uploaded by your doctor will appear here',
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getFileIcon(document.fileType),
                                  color: Theme.of(context).primaryColor,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        document.fileName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Uploaded: ${DateFormat('MMM dd, yyyy').format(document.uploadDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (document.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          document.description!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'download':
                                        _downloadDocument(document);
                                        break;
                                      case 'history':
                                        _viewAuditLogs(document);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
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
                                      value: 'history',
                                      child: Row(
                                        children: [
                                          Icon(Icons.history),
                                          SizedBox(width: 8),
                                          Text('View History'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfoChip(
                                  '${(document.fileSize / 1024).toStringAsFixed(1)} KB',
                                  Icons.storage,
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  document.fileType.toUpperCase(),
                                  Icons.file_present,
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  document.accessLevel.toUpperCase(),
                                  Icons.security,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
}

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
import '../../components/ui_kit.dart';
import '../../../translations.dart';


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
          SnackBar(content: Text(context.tr('documentDownloadedSuccessfully'))),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('failedToDownloadDocument'))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('errorDownloadingDocument')}: $e')),
      );
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
        title: Text(context.tr('documentHistory')),
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
                  '${DateFormat('MMM dd, yyyy HH:mm', Localizations.localeOf(context).languageCode).format(log.timestamp)}\n'
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
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('medicalDocuments')),
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
          SectionHeader(
            title: context.tr('medicalDocuments'),
            subtitle: context.tr('prescriptionsLabResultsAndMore'),
          ),
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
                  hint: Text(context.tr('filterByPetOptional')),
                  items: [
                    DropdownMenuItem<Pet?>(
                      value: null,
                      child: Text(context.tr('allPets')),
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
                  return EmptyState(
                    icon: Icons.description,
                    title: context.tr('noMedicalDocumentsFound'),
                    message: context.tr('documentsUploadedByDoctorWillAppearHere'),
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
                                        '${context.tr('uploadedLabel')} ${DateFormat('MMM dd, yyyy', Localizations.localeOf(context).languageCode).format(document.uploadDate)}',
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
                                    PopupMenuItem(
                                      value: 'download',
                                      child: Row(
                                        children: [
                                          Icon(Icons.download),
                                          SizedBox(width: 8),
                                          Text(context.tr('download')),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'history',
                                      child: Row(
                                        children: [
                                          Icon(Icons.history),
                                          SizedBox(width: 8),
                                          Text(context.tr('viewHistory')),
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








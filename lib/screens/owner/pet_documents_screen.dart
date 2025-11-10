// lib/screens/owner/pet_documents_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/pet.dart';
import '../../models/document.dart';
import '../../providers/pet_provider.dart';

class PetDocumentsScreen extends StatefulWidget {
  final Pet pet;

  const PetDocumentsScreen({super.key, required this.pet});

  @override
  State<PetDocumentsScreen> createState() => _PetDocumentsScreenState();
}

class _PetDocumentsScreenState extends State<PetDocumentsScreen> {
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pet.id != null) {
        context.read<PetProvider>().loadDocuments(widget.pet.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.pet.name} documents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          final documents = petProvider.getDocumentsByPet(widget.pet.id ?? -1);
          if (documents.isEmpty) {
            return const Center(
              child: Text('No documents uploaded yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                child: ListTile(
                  leading: Icon(_iconForType(doc.fileType)),
                  title: Text(doc.fileName),
                  subtitle: Text(
                    'Uploaded ${_dateFormat.format(doc.uploadDate.toLocal())}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteDocument(doc),
                  ),
                  onTap: () => _openDocument(doc),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openDocument(Document document) async {
    final path = document.filePath;
    if (path.startsWith('http') && await canLaunchUrlString(path)) {
      await launchUrlString(path, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only web URLs can be opened in this demo build.'),
        ),
      );
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document'),
        content: Text('Remove ${document.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<PetProvider>().deleteDocument(document.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document removed')), 
      );
    }
  }

  Future<void> _showUploadDialog() async {
    if (widget.pet.id == null) return;
    final result = await showDialog<Document>(
      context: context,
      builder: (context) => _DocumentUploadDialog(petId: widget.pet.id!),
    );

    if (result != null) {
      await context.read<PetProvider>().addDocument(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded')), 
      );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

class _DocumentUploadDialog extends StatefulWidget {
  final int petId;

  const _DocumentUploadDialog({required this.petId});

  @override
  State<_DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<_DocumentUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fileNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  String _type = 'image';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload document'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fileNameController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'image', child: Text('Image')), 
                DropdownMenuItem(value: 'pdf', child: Text('PDF')), 
                DropdownMenuItem(value: 'document', child: Text('Document')), 
              ],
              onChanged: (value) => setState(() => _type = value ?? 'image'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Link or file path',
                helperText: 'Paste a public URL to the file or image',
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
          ],
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
              Document(
                petId: widget.petId,
                fileName: _fileNameController.text,
                fileType: _type,
                filePath: _urlController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                uploadDate: DateTime.now(),
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
    _fileNameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}

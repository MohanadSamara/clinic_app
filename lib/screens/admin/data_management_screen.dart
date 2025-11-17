import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../db/db_helper.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting data...';
    });

    try {
      final data = await DBHelper.instance.exportData();
      final jsonString = jsonEncode(data);
      final fileName =
          'vet_clinic_backup_${DateTime.now().toIso8601String().split('T')[0]}.json';

      // For web/mobile, use share_plus to save/share the file
      // For simplicity, copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      setState(() {
        _statusMessage =
            'Data exported to clipboard. You can paste it into a file named $fileName';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported to clipboard')),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Export failed: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the exported JSON data below:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON data here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != true || controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing data...';
    });

    try {
      final data = jsonDecode(controller.text) as Map<String, dynamic>;
      await DBHelper.instance.importData(data);

      setState(() {
        _statusMessage = 'Data imported successfully';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data imported successfully')),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Import failed: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Backup & Restore',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use these functions to backup your data and restore it in different terminals or devices.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('failed')
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusMessage),
                ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportData,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _importData,
                      icon: const Icon(Icons.upload),
                      label: const Text('Import Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to use:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Export data from one terminal to backup your current data.',
                      ),
                      Text('2. Copy the exported JSON data.'),
                      Text(
                        '3. In another terminal, import the data to restore it.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Note: Importing will replace all existing data. Make sure to backup first.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

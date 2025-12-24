import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../providers/auth_provider.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final logs = await DBHelper.instance.getAllComplianceLogs();
      setState(() => _logs = logs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading compliance logs: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addLog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ComplianceLogDialog(),
    );
    if (result != null) {
      try {
        await DBHelper.instance.insertComplianceLog(result);
        _loadLogs();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compliance log added')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding log: $e')));
      }
    }
  }

  Future<void> _editLog(Map<String, dynamic> log) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ComplianceLogDialog(log: log),
    );
    if (result != null) {
      try {
        await DBHelper.instance.updateComplianceLog(log['id'], result);
        _loadLogs();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compliance log updated')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating log: $e')));
      }
    }
  }

  Future<void> _deleteLog(Map<String, dynamic> log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Compliance Log'),
        content: Text('Are you sure you want to delete this log?'),
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

    if (confirm == true) {
      try {
        await DBHelper.instance.deleteComplianceLog(log['id']);
        _loadLogs();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compliance log deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting log: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is admin
    if (auth.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to access this page.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance & Records'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addLog)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text('No compliance logs found'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(log['inspection_type'] ?? 'Unknown Type'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inspector: ${log['inspector_name'] ?? 'N/A'}'),
                        Text('Date: ${log['inspection_date'] ?? 'N/A'}'),
                        Text('Status: ${log['status'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editLog(log);
                        } else if (value == 'delete') {
                          _deleteLog(log);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () => _showLogDetails(log),
                  ),
                );
              },
            ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log['inspection_type'] ?? 'Compliance Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Inspector: ${log['inspector_name'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Inspection Date: ${log['inspection_date'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Status: ${log['status'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Findings: ${log['findings'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Corrective Actions: ${log['corrective_actions'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Next Inspection: ${log['next_inspection_date'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ComplianceLogDialog extends StatefulWidget {
  final Map<String, dynamic>? log;

  const ComplianceLogDialog({super.key, this.log});

  @override
  State<ComplianceLogDialog> createState() => _ComplianceLogDialogState();
}

class _ComplianceLogDialogState extends State<ComplianceLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inspectionTypeController = TextEditingController();
  final _inspectorNameController = TextEditingController();
  final _inspectionDateController = TextEditingController();
  final _statusController = TextEditingController();
  final _findingsController = TextEditingController();
  final _correctiveActionsController = TextEditingController();
  final _nextInspectionDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.log != null) {
      _inspectionTypeController.text = widget.log!['inspection_type'] ?? '';
      _inspectorNameController.text = widget.log!['inspector_name'] ?? '';
      _inspectionDateController.text = widget.log!['inspection_date'] ?? '';
      _statusController.text = widget.log!['status'] ?? '';
      _findingsController.text = widget.log!['findings'] ?? '';
      _correctiveActionsController.text =
          widget.log!['corrective_actions'] ?? '';
      _nextInspectionDateController.text =
          widget.log!['next_inspection_date'] ?? '';
    }
  }

  @override
  void dispose() {
    _inspectionTypeController.dispose();
    _inspectorNameController.dispose();
    _inspectionDateController.dispose();
    _statusController.dispose();
    _findingsController.dispose();
    _correctiveActionsController.dispose();
    _nextInspectionDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.log == null ? 'Add Compliance Log' : 'Edit Compliance Log',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _inspectionTypeController,
                decoration: const InputDecoration(labelText: 'Inspection Type'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _inspectorNameController,
                decoration: const InputDecoration(labelText: 'Inspector Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _inspectionDateController,
                decoration: const InputDecoration(labelText: 'Inspection Date'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _findingsController,
                decoration: const InputDecoration(labelText: 'Findings'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _correctiveActionsController,
                decoration: const InputDecoration(
                  labelText: 'Corrective Actions',
                ),
                maxLines: 3,
              ),
              TextFormField(
                controller: _nextInspectionDateController,
                decoration: const InputDecoration(
                  labelText: 'Next Inspection Date',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'inspection_type': _inspectionTypeController.text,
        'inspector_name': _inspectorNameController.text,
        'inspection_date': _inspectionDateController.text,
        'status': _statusController.text,
        'findings': _findingsController.text,
        'corrective_actions': _correctiveActionsController.text,
        'next_inspection_date': _nextInspectionDateController.text,
        'created_at': DateTime.now().toIso8601String(),
      };
      Navigator.pop(context, data);
    }
  }
}








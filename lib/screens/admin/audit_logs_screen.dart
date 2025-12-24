import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedAction = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _actionTypes = [
    'all',
    'update_user_role',
    'delete_user',
    'link_users',
    'unlink_users',
    'update_setting',
    'add_service',
    'update_service',
    'delete_service',
    'assign_van',
    'unassign_van',
  ];

  @override
  void initState() {
    super.initState();
    // Delay loading until after the first build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAuditLogs();
    });
  }

  Future<void> _loadAuditLogs() async {
    final adminProvider = context.read<AdminProvider>();
    await adminProvider.loadAuditLogs();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  List<Map<String, dynamic>> _filterLogs(List<Map<String, dynamic>> logs) {
    return logs.where((log) {
      // Filter by action type
      if (_selectedAction != 'all' && log['action'] != _selectedAction) {
        return false;
      }

      // Filter by search text
      final searchText = _searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        final details = log['details']?.toString().toLowerCase() ?? '';
        if (!details.contains(searchText)) {
          return false;
        }
      }

      // Filter by date range
      if (_startDate != null || _endDate != null) {
        final logDate = DateTime.parse(log['timestamp']);
        if (_startDate != null && logDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null &&
            logDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _formatAction(String action) {
    return action
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'delete_user':
      case 'unlink_users':
        return Colors.red;
      case 'update_user_role':
      case 'update_setting':
      case 'update_service':
        return Colors.orange;
      case 'link_users':
      case 'assign_van':
        return Colors.green;
      case 'add_service':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search in details',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAction,
                          decoration: const InputDecoration(
                            labelText: 'Action Type',
                            border: OutlineInputBorder(),
                          ),
                          items: _actionTypes.map((action) {
                            return DropdownMenuItem(
                              value: action,
                              child: Text(
                                action == 'all'
                                    ? 'All Actions'
                                    : _formatAction(action),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedAction = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectStartDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _startDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ).format(_startDate!)
                                : 'Start Date',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectEndDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _endDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ).format(_endDate!)
                                : 'End Date',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear dates',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Logs List
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredLogs = _filterLogs(adminProvider.auditLogs);

                if (filteredLogs.isEmpty) {
                  return const Center(child: Text('No audit logs found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final timestamp = DateTime.parse(log['timestamp']);
                    final actionColor = _getActionColor(log['action']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: actionColor.withOpacity(0.2),
                          child: Icon(
                            _getActionIcon(log['action']),
                            color: actionColor,
                          ),
                        ),
                        title: Text(_formatAction(log['action'])),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log['details'] ?? 'No details',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                                Localizations.localeOf(context).languageCode,
                              ).format(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showLogDetails(log),
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

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'delete_user':
        return Icons.delete;
      case 'update_user_role':
        return Icons.edit;
      case 'link_users':
      case 'unlink_users':
        return Icons.link;
      case 'update_setting':
        return Icons.settings;
      case 'add_service':
      case 'update_service':
      case 'delete_service':
        return Icons.medical_services;
      case 'assign_van':
      case 'unassign_van':
        return Icons.directions_car;
      default:
        return Icons.info;
    }
  }

  void _showLogDetails(Map<String, dynamic> log) {
    final timestamp = DateTime.parse(log['timestamp']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatAction(log['action'])),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Details: ${log['details'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Timestamp: ${DateFormat('MMM dd, yyyy HH:mm:ss', Localizations.localeOf(context).languageCode).format(timestamp)}',
              ),
              if (log['user_id'] != null) ...[
                const SizedBox(height: 8),
                Text('User ID: ${log['user_id']}'),
              ],
              if (log['document_id'] != null) ...[
                const SizedBox(height: 8),
                Text('Document ID: ${log['document_id']}'),
              ],
              if (log['ip_address'] != null) ...[
                const SizedBox(height: 8),
                Text('IP Address: ${log['ip_address']}'),
              ],
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








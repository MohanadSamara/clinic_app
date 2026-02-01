import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_complete_service.dart';
import '../../providers/auth_provider.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isConnected = false;
  Map<String, dynamic> _connectionInfo = {};
  List<String> _tables = [];
  List<Map<String, dynamic>> _tableData = [];
  String _selectedTable = '';
  final TextEditingController _jsonController = TextEditingController();
  bool _isJsonValid = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadTables();
  }

  Future<void> _checkConnection() async {
    try {
      final supabase = SupabaseCompleteService.instance;

      // Test connection by getting a simple query
      final response = await supabase.client
          .from('users')
          .select('id')
          .limit(1);

      setState(() {
        _isConnected = response != null && response.isNotEmpty;
        _connectionInfo = {
          'url': 'Supabase Cloud',
          'status': _isConnected ? 'Connected' : 'Disconnected',
          'server_version': 'Cloud Database',
        };
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionInfo = {
          'url': 'Supabase',
          'status': 'Error: ${e.toString()}',
          'server_version': 'Unknown',
        };
      });
    }
  }

  Future<void> _loadTables() async {
    try {
      final supabase = SupabaseCompleteService.instance;

      // Get list of tables from information_schema
      final response = await supabase.client
          .from('information_schema.tables')
          .select('table_name')
          .eq('table_schema', 'public');

      if (response != null && response.isNotEmpty) {
        setState(() {
          _tables = List<String>.from(response.map((e) => e['table_name']));
        });
      }
    } catch (e) {
      debugPrint('Error loading tables: $e');
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _isLoading = true;
      _selectedTable = tableName;
    });

    try {
      final supabase = SupabaseCompleteService.instance;
      final response = await supabase.client.from(tableName).select();

      setState(() {
        _tableData = List<Map<String, dynamic>>.from(response ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _tableData = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _exportTableData(String tableName) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting data from $tableName...';
    });

    try {
      final supabase = SupabaseCompleteService.instance;
      final response = await supabase.client.from(tableName).select();

      final data = response ?? [];
      final jsonString = jsonEncode(data);

      await Clipboard.setData(ClipboardData(text: jsonString));

      setState(() {
        _statusMessage =
            'Data exported to clipboard. Table: $tableName (${data.length} rows)';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${data.length} rows from $tableName'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Export failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
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
              controller: _jsonController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '[{"column": "value"}, ...]',
                labelText: 'JSON Data',
              ),
              onChanged: (value) {
                try {
                  jsonDecode(value);
                  setState(() => _isJsonValid = true);
                } catch (e) {
                  setState(() => _isJsonValid = false);
                }
              },
            ),
            if (!_isJsonValid)
              const Text(
                'Invalid JSON format',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isJsonValid ? () => Navigator.pop(context, true) : null,
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != true || _jsonController.text.isEmpty) {
      _jsonController.clear();
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing data...';
    });

    try {
      final data = jsonDecode(_jsonController.text) as List<dynamic>;

      // Show dialog to select table
      final tableName = await _showTableSelectionDialog();
      if (tableName == null) {
        _jsonController.clear();
        setState(() => _isLoading = false);
        return;
      }

      final supabase = SupabaseCompleteService.instance;
      int successCount = 0;

      for (final item in data) {
        try {
          await supabase.client
              .from(tableName)
              .insert(item as Map<String, dynamic>);
          successCount++;
        } catch (e) {
          debugPrint('Error inserting item: $e');
        }
      }

      setState(() {
        _statusMessage =
            'Imported $successCount rows successfully into $tableName';
      });

      _jsonController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $successCount rows successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Import failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _showTableSelectionDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _tables.map((table) {
              return ListTile(
                title: Text(table),
                onTap: () => Navigator.pop(context, table),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showApiInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supabase API Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This app uses Supabase as its backend database.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Available operations:'),
              const Text('• View all tables in the database'),
              const Text('• Export data from any table to JSON'),
              const Text('• Import JSON data into tables'),
              const SizedBox(height: 16),
              const Text(
                'Note: Supabase is a cloud database, so all data is stored remotely and synced across all devices.',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        title: const Text('Data Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showApiInfo,
            tooltip: 'API Information',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar with tables list
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.cloud_done : Icons.cloud_off,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tables: ${_tables.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tables.length,
                    itemBuilder: (context, index) {
                      final table = _tables[index];
                      return ListTile(
                        selected: _selectedTable == table,
                        selectedTileColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        leading: const Icon(Icons.table_chart),
                        title: Text(table),
                        onTap: () => _loadTableData(table),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _importData,
                        icon: const Icon(Icons.upload),
                        label: const Text('Import Data'),
                      ),
                      const SizedBox(width: 16),
                      if (_selectedTable.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _exportTableData(_selectedTable),
                          icon: const Icon(Icons.download),
                          label: Text('Export $_selectedTable'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Table data preview
                  if (_selectedTable.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          '$_selectedTable Data',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_tableData.length} rows',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_tableData.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No data in this table')),
                        ),
                      )
                    else
                      Expanded(
                        child: Card(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _tableData.take(10).map((row) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: row.entries.map((entry) {
                                      return Text(
                                        '${entry.key}: ${entry.value?.toString() ?? 'null'}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    if (_tableData.length > 10)
                      Center(
                        child: Text(
                          'Showing first 10 of ${_tableData.length} rows',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ] else ...[
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storage, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Select a table to view data',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

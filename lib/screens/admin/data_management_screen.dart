import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../providers/auth_provider.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  final TextEditingController _sqlController = TextEditingController();
  List<Map<String, dynamic>> _queryResults = [];
  String _queryError = '';
  bool _isQueryLoading = false;
  Map<String, dynamic>? _dbInfo;
  bool _isLoadingDbInfo = false;

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

  Future<void> _executeQuery() async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) {
      setState(() {
        _queryError = 'Please enter a SQL query';
        _queryResults = [];
      });
      return;
    }

    setState(() {
      _isQueryLoading = true;
      _queryError = '';
      _queryResults = [];
    });

    try {
      final results = await DBHelper.instance.executeRawQuery(sql);
      setState(() {
        _queryResults = results;
      });
    } catch (e) {
      setState(() {
        _queryError = 'Query failed: $e';
      });
    } finally {
      setState(() {
        _isQueryLoading = false;
      });
    }
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() {
      _isLoadingDbInfo = true;
    });

    try {
      final info = await DBHelper.instance.getDatabaseInfo();
      setState(() {
        _dbInfo = info;
      });
    } catch (e) {
      setState(() {
        _dbInfo = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoadingDbInfo = false;
      });
    }
  }

  Future<void> _openDatabaseLocation() async {
    if (_dbInfo == null || _dbInfo!['exists'] == false) return;

    final path = _dbInfo!['path'] as String;
    final directory = path.substring(
      0,
      path.lastIndexOf(Platform.pathSeparator),
    );

    // For mobile platforms and web, just copy path to clipboard
    bool isMobileOrWeb = false;
    try {
      // Only access Platform class on non-web platforms
      if (!kIsWeb) {
        isMobileOrWeb = Platform.isAndroid || Platform.isIOS || kIsWeb;
      } else {
        isMobileOrWeb = true; // Web is always mobile/web
      }
    } catch (e) {
      // If Platform access fails, assume it's not mobile/web
      isMobileOrWeb = false;
    }

    if (isMobileOrWeb) {
      await Clipboard.setData(ClipboardData(text: path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database path copied to clipboard')),
        );
      }
      return;
    }

    try {
      // Try to open the directory using platform-specific commands (desktop only)
      bool isDesktop = false;
      try {
        // Only access Platform class on non-web platforms
        if (!kIsWeb) {
          isDesktop =
              Platform.isWindows || Platform.isMacOS || Platform.isLinux;
        }
      } catch (e) {
        // If Platform access fails, assume it's not desktop
        isDesktop = false;
      }

      if (isDesktop) {
        // Only access Platform class on non-web platforms
        if (!kIsWeb) {
          if (Platform.isWindows) {
            await Process.run('cmd', ['/c', 'start', directory]);
          } else if (Platform.isMacOS) {
            await Process.run('open', [directory]);
          } else if (Platform.isLinux) {
            await Process.run('xdg-open', [directory]);
          } else {
            throw UnsupportedError(
              'Platform not supported for directory opening',
            );
          }
        } else {
          throw UnsupportedError(
            'Platform not supported for directory opening',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database location opened')),
          );
        }
      } else {
        throw UnsupportedError('Platform not supported for directory opening');
      }
    } catch (e) {
      // Fallback: copy path to clipboard
      await Clipboard.setData(ClipboardData(text: path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open location. Path copied to clipboard: $path',
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyDatabaseForExternalAccess() async {
    setState(() {
      _isLoadingDbInfo = true;
    });

    try {
      final copiedPath = await DBHelper.instance
          .copyDatabaseForExternalAccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database copied to: $copiedPath')),
        );
      }

      // Show instructions for accessing with external tools
      _showExternalAccessInstructions(copiedPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error copying database: $e')));
      }
    } finally {
      setState(() {
        _isLoadingDbInfo = false;
      });
    }
  }

  void _showExternalAccessInstructions(String databasePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Access Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You can now access your database file using external tools:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Command Line Interface (CLI):'),
              const Text(
                '   - Download SQLite3 from: https://sqlite.org/download.html',
              ),
              const Text('   - Open terminal/command prompt'),
              Text('   - Navigate to: $databasePath'),
              const Text('   - Run: sqlite3 vet_clinic_export.db'),
              const Text('   - Use SQL commands to query data'),
              const SizedBox(height: 12),
              const Text('2. Graphical User Interface (GUI):'),
              const Text(
                '   - Download DB Browser for SQLite: https://sqlitebrowser.org/',
              ),
              const Text('   - Open the application'),
              Text('   - Open database file: $databasePath'),
              const Text('   - Browse tables, run queries, export data'),
              const SizedBox(height: 12),
              const Text('3. Other Tools:'),
              const Text('   - SQLiteStudio: https://sqlitestudio.pl/'),
              const Text('   - SQLite Manager (Firefox extension)'),
              const Text('   - Various mobile SQLite browser apps'),
              const SizedBox(height: 16),
              const Text(
                'Common SQL queries:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('   - SELECT * FROM users;'),
              const Text('   - SELECT * FROM appointments;'),
              const Text('   - SELECT * FROM pets;'),
              const Text('   - SELECT * FROM payments;'),
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
      appBar: AppBar(title: const Text('Data Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backup & Restore',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'SQL Query Console',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Execute custom SQL queries on the database. Use SELECT for read operations, and be careful with UPDATE/DELETE/INSERT as they modify data.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sqlController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Enter SQL query here...\nExample: SELECT * FROM users LIMIT 10;',
                        labelText: 'SQL Query',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isQueryLoading ? null : _executeQuery,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Execute Query'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            _sqlController.clear();
                            setState(() {
                              _queryResults = [];
                              _queryError = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isQueryLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_queryError.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_queryError),
                      )
                    else if (_queryResults.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Query Results (${_queryResults.length} rows)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300, // Fixed height for results
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: _queryResults.isNotEmpty
                                          ? _queryResults.first.keys
                                                .map(
                                                  (key) => DataColumn(
                                                    label: Text(key),
                                                  ),
                                                )
                                                .toList()
                                          : [],
                                      rows: _queryResults.map((row) {
                                        return DataRow(
                                          cells: row.keys.map((key) {
                                            final value =
                                                row[key]?.toString() ?? '';
                                            return DataCell(
                                              Text(
                                                value.length > 50
                                                    ? '${value.substring(0, 50)}...'
                                                    : value,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Database File Access',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'View database file information and access the SQLite database file directly.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingDbInfo
                                ? null
                                : _loadDatabaseInfo,
                            icon: const Icon(Icons.info),
                            label: const Text('Load Database Info'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingDbInfo
                                ? null
                                : _copyDatabaseForExternalAccess,
                            icon: const Icon(Icons.file_copy),
                            label: const Text('Copy for External Tools'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingDbInfo
                                ? null
                                : _openDatabaseLocation,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Open Database Location'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingDbInfo)
                      const Center(child: CircularProgressIndicator())
                    else if (_dbInfo != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Database Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_dbInfo!.containsKey('error'))
                                Text(
                                  'Error: ${_dbInfo!['error']}',
                                  style: const TextStyle(color: Colors.red),
                                )
                              else ...[
                                _buildInfoRow('Platform', _dbInfo!['platform']),
                                _buildInfoRow('File Path', _dbInfo!['path']),
                                _buildInfoRow(
                                  'File Exists',
                                  _dbInfo!['exists'] ? 'Yes' : 'No',
                                ),
                                if (_dbInfo!['exists'])
                                  _buildInfoRow(
                                    'File Size',
                                    '${(_dbInfo!['size'] as int) ~/ 1024} KB',
                                  ),
                                if (_dbInfo!['exists'])
                                  _buildInfoRow(
                                    'Last Modified',
                                    _dbInfo!['lastModified'],
                                  ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Note: For desktop platforms, you can use SQLite browser tools to open and examine the database file directly.',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

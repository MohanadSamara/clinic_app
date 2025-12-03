import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';

class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  final List<String> _ammanDistricts = [
    'Amman Qasaba District',
    'Al-Jami\'a District',
    'Marka District',
    'Al-Qweismeh District',
    'Wadi Al-Sir District',
    'Al-Jizah District',
    'Sahab District',
    'Dabouq District (new)',
    'Naour District',
  ];

  Map<String, List<User>> _usersByArea = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersByArea();
  }

  Future<void> _loadUsersByArea() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DBHelper.instance;
      final allUsers = await dbHelper.getAllUsers();

      final usersByArea = <String, List<User>>{};

      // Initialize all districts
      for (final district in _ammanDistricts) {
        usersByArea[district] = [];
      }

      // Group users by area
      for (final userData in allUsers) {
        final user = User.fromMap(userData);
        if (user.role == 'doctor' || user.role == 'driver') {
          final area = user.area ?? 'Not specified';
          if (!usersByArea.containsKey(area)) {
            usersByArea[area] = [];
          }
          usersByArea[area]!.add(user);
        }
      }

      setState(() {
        _usersByArea = usersByArea;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users by area: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsersByArea,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ammanDistricts.length,
                itemBuilder: (context, index) {
                  final area = _ammanDistricts[index];
                  final users = _usersByArea[area] ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        area,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${users.length} service providers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          users.length.toString(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      children: users.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No service providers in this area',
                                ),
                              ),
                            ]
                          : users.map((user) {
                              final isLinked =
                                  user.linkedDoctorId != null ||
                                  user.linkedDriverId != null;

                              return ListTile(
                                title: Text(user.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${user.email} • ${user.role}'),
                                    if (isLinked)
                                      Text(
                                        'Linked to team',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Not linked',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: user.role == 'doctor'
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                                  child: Icon(
                                    user.role == 'doctor'
                                        ? Icons.medical_services
                                        : Icons.drive_eta,
                                    color: user.role == 'doctor'
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                ),
                                trailing: isLinked
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      )
                                    : Icon(
                                        Icons.warning,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                              );
                            }).toList(),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

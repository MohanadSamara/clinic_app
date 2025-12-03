import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';
import '../../models/van.dart';
import '../../providers/van_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final userMaps = await DBHelper.instance.getAllUsers();
      final users = userMaps.map((map) => User.fromMap(map)).toList();
      setState(() => _users = users);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    try {
      await DBHelper.instance.updateUser(user.id!, {'role': newRole});
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = user.copyWith(role: newRole);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User role updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating role: $e')));
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
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
        await DBHelper.instance.deleteUser(user.id!);
        setState(() => _users.removeWhere((u) => u.id == user.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
      }
    }
  }

  Future<void> _linkDoctorToDriver(User doctor) async {
    final doctorArea = doctor.area ?? 'Not specified';
    final availableDrivers = _users
        .where(
          (u) =>
              u.role == 'driver' &&
              u.linkedDoctorId == null &&
              (u.area ?? 'Not specified') == doctorArea,
        )
        .toList();

    if (availableDrivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No available drivers in the same area (${doctorArea}) to link',
          ),
        ),
      );
      return;
    }

    final selectedDriver = await showDialog<User>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Doctor to Driver'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableDrivers.length,
            itemBuilder: (context, index) {
              final driver = availableDrivers[index];
              return ListTile(
                title: Text(driver.name),
                subtitle: Text(driver.email),
                onTap: () => Navigator.of(context).pop(driver),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedDriver != null) {
      try {
        // Link the users first
        await DBHelper.instance.updateUser(doctor.id!, {
          'linked_driver_id': selectedDriver.id,
        });
        await DBHelper.instance.updateUser(selectedDriver.id!, {
          'linked_doctor_id': doctor.id,
        });

        // Update local state
        setState(() {
          final doctorIndex = _users.indexWhere((u) => u.id == doctor.id);
          final driverIndex = _users.indexWhere(
            (u) => u.id == selectedDriver.id,
          );
          if (doctorIndex != -1) {
            _users[doctorIndex] = doctor.copyWith(
              linkedDriverId: selectedDriver.id,
            );
          }
          if (driverIndex != -1) {
            _users[driverIndex] = selectedDriver.copyWith(
              linkedDoctorId: doctor.id,
            );
          }
        });

        // Now require van assignment
        await _assignVanToLinkedPair(doctor, selectedDriver);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error linking users: $e')));
      }
    }
  }

  Future<void> _assignVanToLinkedPair(User doctor, User driver) async {
    final vanProvider = context.read<VanProvider>();
    await vanProvider.loadVans();

    final availableVans = vanProvider.getAvailableVans();

    if (availableVans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No available vans to assign. Please create vans first.',
          ),
        ),
      );
      return;
    }

    final selectedVan = await showDialog<Van>(
      context: context,
      barrierDismissible: false, // Make it mandatory
      builder: (context) => AlertDialog(
        title: const Text('Assign Van to Team'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dr. ${doctor.name} and ${driver.name} have been linked. You must assign them to a van to complete the process.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Available Vans:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableVans.length,
                  itemBuilder: (context, index) {
                    final van = availableVans[index];
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(van.name),
                      subtitle: Text('License: ${van.licensePlate}'),
                      onTap: () => Navigator.of(context).pop(van),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel Linking'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (selectedVan != null) {
      try {
        await vanProvider.assignVanToDoctorAndDriver(
          selectedVan.id!,
          doctor.id!,
          driver.id!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully linked Dr. ${doctor.name} to ${driver.name} and assigned van "${selectedVan.name}"',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error assigning van: $e')));
      }
    } else {
      // If no van was selected, undo the linking
      try {
        await DBHelper.instance.updateUser(doctor.id!, {
          'linked_driver_id': null,
        });
        await DBHelper.instance.updateUser(driver.id!, {
          'linked_doctor_id': null,
        });

        setState(() {
          final doctorIndex = _users.indexWhere((u) => u.id == doctor.id);
          final driverIndex = _users.indexWhere((u) => u.id == driver.id);
          if (doctorIndex != -1) {
            _users[doctorIndex] = doctor.copyWith(linkedDriverId: null);
          }
          if (driverIndex != -1) {
            _users[driverIndex] = driver.copyWith(linkedDoctorId: null);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linking cancelled - no van assigned')),
        );
      } catch (e) {
        debugPrint('Error undoing linking: $e');
      }
    }
  }

  Future<void> _unlinkDoctor(User doctor) async {
    if (doctor.linkedDriverId == null) return;

    final driver = _users.firstWhere(
      (u) => u.id == doctor.linkedDriverId,
      orElse: () => User(name: 'Unknown Driver', email: '', password: ''),
    );

    try {
      await DBHelper.instance.updateUser(doctor.id!, {
        'linked_driver_id': null,
      });
      await DBHelper.instance.updateUser(driver.id!, {
        'linked_doctor_id': null,
      });
      setState(() {
        final doctorIndex = _users.indexWhere((u) => u.id == doctor.id);
        final driverIndex = _users.indexWhere((u) => u.id == driver.id);
        if (doctorIndex != -1) {
          _users[doctorIndex] = doctor.copyWith(linkedDriverId: null);
        }
        if (driverIndex != -1) {
          _users[driverIndex] = driver.copyWith(linkedDoctorId: null);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlinked ${doctor.name} from ${driver.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error unlinking users: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user.email} - ${user.role}'),
                        if ((user.role == 'doctor' || user.role == 'driver') &&
                            user.area != null)
                          Text(
                            'Area: ${user.area}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.purple,
                            ),
                          ),
                        if (user.role == 'doctor' &&
                            user.linkedDriverId != null)
                          Text(
                            'Linked to driver: ${_users.firstWhere(
                              (u) => u.id == user.linkedDriverId,
                              orElse: () => User(name: 'Unknown Driver', email: '', password: ''),
                            ).name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          )
                        else if (user.role == 'driver' &&
                            user.linkedDoctorId != null)
                          Text(
                            'Linked to doctor: ${_users.firstWhere(
                              (u) => u.id == user.linkedDoctorId,
                              orElse: () => User(name: 'Unknown Doctor', email: '', password: ''),
                            ).name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteUser(user);
                        } else if (value == 'link_doctor') {
                          _linkDoctorToDriver(user);
                        } else if (value == 'unlink_doctor') {
                          _unlinkDoctor(user);
                        } else {
                          _updateUserRole(user, value);
                        }
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'owner',
                            child: Text('Set as Owner'),
                          ),
                          const PopupMenuItem(
                            value: 'doctor',
                            child: Text('Set as Doctor'),
                          ),
                          const PopupMenuItem(
                            value: 'driver',
                            child: Text('Set as Driver'),
                          ),
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text('Set as Admin'),
                          ),
                        ];

                        if (user.role == 'doctor') {
                          items.add(const PopupMenuDivider());
                          if (user.linkedDriverId == null) {
                            items.add(
                              const PopupMenuItem(
                                value: 'link_doctor',
                                child: Text('Link to Driver'),
                              ),
                            );
                          } else {
                            items.add(
                              const PopupMenuItem(
                                value: 'unlink_doctor',
                                child: Text('Unlink from Driver'),
                              ),
                            );
                          }
                        }

                        items.add(const PopupMenuDivider());
                        items.add(
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete User'),
                          ),
                        );

                        return items;
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

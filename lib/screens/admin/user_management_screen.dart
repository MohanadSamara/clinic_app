import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';
import '../../models/van.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/van_provider.dart';
import '../../../translations.dart';


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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('errorLoadingUsers')}: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    if (user.role == newRole) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('userAlreadyHasRole'))));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('confirmRoleChange')),
        content: Text(
          'Change ${user.name}\'s role from ${user.role} to $newRole?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await DBHelper.instance.updateUser(user.id!, {'role': newRole});
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = user.copyWith(role: newRole);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('userRoleUpdated')} $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('errorUpdatingRole')}: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(User user) async {
    // Prevent deleting the current admin user
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cannotDeleteOwnAccount'))),
      );
      return;
    }

    // Check if user has active links
    if (user.role == 'doctor' && user.linkedDriverId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cannotDeleteDoctorWithActiveLink'))),
      );
      return;
    }

    if (user.role == 'driver' && user.linkedDoctorId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cannotDeleteDriverWithActiveLink'))),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deleteUser')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.tr('areYouSureDelete')} ${user.name}?'),
            const SizedBox(height: 8),
            Text(
              context.tr('permanentDeleteWarning'),
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await DBHelper.instance.deleteUser(user.id!);
      setState(() => _users.removeWhere((u) => u.id == user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} ${context.tr('hasBeenDeleted')}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('errorDeletingUser')}: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() => _loading = false);
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
            '${context.tr('noAvailableDriversInArea')} (${doctorArea})',
          ),
        ),
      );
      return;
    }

    final selectedDriver = await showDialog<User>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('linkDoctorToDriver')),
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
            child: Text(context.tr('cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('errorLinkingUsers')}: $e')),
        );
      }
    }
  }

  Future<void> _assignVanToLinkedPair(User doctor, User driver) async {
    final vanProvider = context.read<VanProvider>();
    await vanProvider.loadVans();

    final availableVans = vanProvider.getAvailableVans();

    if (availableVans.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('noAvailableVans'))));
      return;
    }

    final selectedVan = await showDialog<Van>(
      context: context,
      barrierDismissible: false, // Make it mandatory
      builder: (context) => AlertDialog(
        title: Text(context.tr('assignVanToTeam')),
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
                      subtitle: Text(
                        '${context.tr('license')}: ${van.licensePlate}',
                      ),
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
            child: Text(context.tr('cancelLinking')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('errorAssigningVan')}: $e')),
        );
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
          SnackBar(content: Text(context.tr('linkingCancelledNoVanAssigned'))),
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
        SnackBar(
          content: Text(
            context.tr(
              'unlinkedFrom',
              args: {'doctorName': doctor.name, 'driverName': driver.name},
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('errorUnlinkingUsers')}: $e')),
      );
    }
  }

  Future<void> _addUser() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'owner';
    String? selectedArea;

    final List<String> ammanDistricts = [
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.tr('addNewUser')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter user\'s full name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Enter email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Enter password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: 'Enter phone number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'owner',
                      child: Text(context.tr('owner')),
                    ),
                    DropdownMenuItem(
                      value: 'doctor',
                      child: Text(context.tr('doctor')),
                    ),
                    DropdownMenuItem(
                      value: 'driver',
                      child: Text(context.tr('driver')),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text(context.tr('admin')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (selectedRole == 'doctor' || selectedRole == 'driver')
                  DropdownButtonFormField<String>(
                    value: selectedArea,
                    decoration: const InputDecoration(
                      labelText: 'Area *',
                      hintText: 'Select service area',
                      border: OutlineInputBorder(),
                    ),
                    items: ammanDistricts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedArea = value);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                // Validation
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('nameRequired'))),
                  );
                  return;
                }

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('emailRequired'))),
                  );
                  return;
                }

                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('enterValidEmail'))),
                  );
                  return;
                }

                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('passwordRequired'))),
                  );
                  return;
                }

                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('passwordMinLength'))),
                  );
                  return;
                }

                if ((selectedRole == 'doctor' || selectedRole == 'driver') &&
                    selectedArea == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('areaRequiredForDoctorsDrivers')),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'name': name,
                  'email': email,
                  'password': password,
                  'phone': phone.isNotEmpty ? phone : null,
                  'role': selectedRole,
                  'area': selectedArea,
                });
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _loading = true);
      try {
        final userData = {
          'name': result['name'],
          'email': result['email'],
          'password': result['password'],
          'phone': result['phone'],
          'role': result['role'],
          'area': result['area'],
        };

        final userId = await DBHelper.instance.insertUser(userData);
        final newUser = User(
          id: userId,
          name: result['name'],
          email: result['email'],
          password: result['password'],
          phone: result['phone'],
          role: result['role'],
          area: result['area'],
        );

        setState(() => _users.add(newUser));

        // Log audit action
        final adminProvider = context.read<AdminProvider>();
        await adminProvider.logAuditAction(
          'add_user',
          'Added new user ${result['name']} with role ${result['role']}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['name']} has been added successfully'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding user: ${e.toString()}')),
        );
      } finally {
        setState(() => _loading = false);
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
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addUser,
            tooltip: context.tr('addNewUser'),
          ),
        ],
      ),
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



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/van_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/van.dart';
import '../../models/user.dart';
import '../../db/db_helper.dart';

class VanManagementScreen extends StatefulWidget {
  const VanManagementScreen({super.key});

  @override
  State<VanManagementScreen> createState() => _VanManagementScreenState();
}

class _VanManagementScreenState extends State<VanManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  String? _selectedArea;

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

  bool _isLoading = false;
  bool _isEditing = false;
  Van? _editingVan;
  List<Map<String, dynamic>> _linkedPairs = [];

  @override
  void initState() {
    super.initState();
    _loadVans();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licensePlateController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVans() async {
    final vanProvider = context.read<VanProvider>();
    await vanProvider.loadVans();
    await _loadLinkedPairs();
  }

  Future<void> _loadLinkedPairs() async {
    try {
      final dbHelper = DBHelper.instance;
      // Get doctors with their linked drivers
      final doctors = await dbHelper.getAllUsers(role: 'doctor');
      final linkedPairs = <Map<String, dynamic>>[];

      for (final doctorData in doctors) {
        final doctor = User.fromMap(doctorData);
        if (doctor.linkedDriverId != null) {
          final driverData = await dbHelper.getUserById(doctor.linkedDriverId!);
          if (driverData != null) {
            final driver = User.fromMap(driverData);
            linkedPairs.add({
              'doctor': doctor,
              'driver': driver,
              'area': doctor.area ?? driver.area ?? 'Not specified',
            });
          }
        }
      }

      setState(() {
        _linkedPairs = linkedPairs;
      });
    } catch (e) {
      debugPrint('Error loading linked pairs: $e');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _licensePlateController.clear();
    _modelController.clear();
    _capacityController.text = '1';
    _descriptionController.clear();
    _selectedArea = null;
    _isEditing = false;
    _editingVan = null;
  }

  void _editVan(Van van) {
    _nameController.text = van.name;
    _licensePlateController.text = van.licensePlate;
    _modelController.text = van.model ?? '';
    _capacityController.text = van.capacity.toString();
    _descriptionController.text = van.description ?? '';
    _selectedArea = van.area;
    _isEditing = true;
    _editingVan = van;
  }

  Future<void> _saveVan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vanProvider = context.read<VanProvider>();
      final van = Van(
        id: _editingVan?.id,
        name: _nameController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 1,
        status: _editingVan?.status ?? 'available',
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        area: _selectedArea,
        assignedDriverId: _editingVan?.assignedDriverId,
        assignedDoctorId: _editingVan?.assignedDoctorId,
        createdAt: _editingVan?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (_isEditing) {
        await vanProvider.updateVan(_editingVan!.id!, van);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Van updated successfully')),
        );
      } else {
        await vanProvider.addVan(van);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Van added successfully')));
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving van: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteVan(Van van) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Van'),
        content: Text(
          'Are you sure you want to delete "${van.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final vanProvider = context.read<VanProvider>();
      await vanProvider.deleteVan(van.id!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Van deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting van: $e')));
    }
  }

  Future<void> _assignVanToPair(Van van, Map<String, dynamic> pair) async {
    final doctor = pair['doctor'] as User;
    final driver = pair['driver'] as User;

    try {
      final vanProvider = context.read<VanProvider>();
      await vanProvider.assignVanToDoctorAndDriver(
        van.id!,
        doctor.id!,
        driver.id!,
      );

      // Update the van's area to match the doctor's area
      final updatedVan = van.copyWith(area: doctor.area);
      await vanProvider.updateVan(van.id!, updatedVan);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Van "${van.name}" assigned to Dr. ${doctor.name} and ${driver.name}',
          ),
        ),
      );

      // Reload data
      await _loadVans();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning van: $e')));
    }
  }

  Future<void> _unassignVan(Van van) async {
    try {
      final vanProvider = context.read<VanProvider>();
      await vanProvider.unassignVanFromDoctorAndDriver(van.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Van unassigned successfully')),
      );

      // Reload data
      await _loadVans();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error unassigning van: $e')));
    }
  }

  Future<Map<String, dynamic>?> _getAssignedTeamInfo(Van van) async {
    if (van.assignedDoctorId == null || van.assignedDriverId == null) {
      return null;
    }

    try {
      final dbHelper = DBHelper.instance;
      final doctorData = await dbHelper.getUserById(van.assignedDoctorId!);
      final driverData = await dbHelper.getUserById(van.assignedDriverId!);

      if (doctorData != null && driverData != null) {
        return {
          'doctor': User.fromMap(doctorData),
          'driver': User.fromMap(driverData),
        };
      }
    } catch (e) {
      debugPrint('Error getting assigned team info: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vanProvider = context.watch<VanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Van Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add/Edit Form
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Van' : 'Add New Van',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Van Name *',
                        hintText: 'e.g., Vet Van Alpha',
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Van name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate *',
                        hintText: 'e.g., VET-001',
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'License plate is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              hintText: 'e.g., Ford Transit',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            decoration: const InputDecoration(
                              labelText: 'Capacity *',
                              hintText: 'Number of passengers',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final capacity = int.tryParse(value ?? '');
                              if (capacity == null || capacity < 1) {
                                return 'Enter valid capacity';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                        hintText: 'Select an area',
                      ),
                      items: _ammanDistricts.map((district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedArea = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveVan,
                            child: Text(_isEditing ? 'Update Van' : 'Add Van'),
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _clearForm,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Vans List
          Expanded(
            child: vanProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vanProvider.vans.isEmpty
                ? const Center(child: Text('No vans found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vanProvider.vans.length,
                    itemBuilder: (context, index) {
                      final van = vanProvider.vans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: van.isFullyAssigned
                                ? Colors.green
                                : van.isPartiallyAssigned
                                ? Colors.orange
                                : Colors.grey,
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(van.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('License: ${van.licensePlate}'),
                              Text('Status: ${van.status}'),
                              if (van.model != null)
                                Text('Model: ${van.model}'),
                              Text('Capacity: ${van.capacity}'),
                              if (van.area != null) Text('Area: ${van.area}'),
                              if (van.isFullyAssigned) ...[
                                FutureBuilder<Map<String, dynamic>?>(
                                  future: _getAssignedTeamInfo(van),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      final doctor =
                                          snapshot.data!['doctor'] as User;
                                      final driver =
                                          snapshot.data!['driver'] as User;
                                      return Text(
                                        'Team: Dr. ${doctor.name} & ${driver.name}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                        ),
                                      );
                                    }
                                    return const Text(
                                      'Fully Assigned',
                                      style: TextStyle(color: Colors.green),
                                    );
                                  },
                                ),
                              ] else if (van.isPartiallyAssigned)
                                const Text(
                                  'Partially Assigned',
                                  style: TextStyle(color: Colors.orange),
                                )
                              else
                                const Text(
                                  'Available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (van.isAvailable && _linkedPairs.isNotEmpty)
                                PopupMenuButton<Map<String, dynamic>>(
                                  icon: const Icon(Icons.assignment),
                                  tooltip: 'Assign to Team',
                                  onSelected: (pair) =>
                                      _assignVanToPair(van, pair),
                                  itemBuilder: (context) => _linkedPairs.map((
                                    pair,
                                  ) {
                                    final doctor = pair['doctor'] as User;
                                    final driver = pair['driver'] as User;
                                    final area = pair['area'] as String;
                                    return PopupMenuItem(
                                      value: pair,
                                      child: Text(
                                        'Dr. ${doctor.name} & ${driver.name} (${area})',
                                      ),
                                    );
                                  }).toList(),
                                ),
                              if (van.isAssigned)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _unassignVan(van),
                                  tooltip: 'Unassign Van',
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editVan(van),
                                tooltip: 'Edit Van',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteVan(van),
                                tooltip: 'Delete Van',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

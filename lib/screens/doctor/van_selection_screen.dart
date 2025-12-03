import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/van_provider.dart';
import '../../models/van.dart';

class DoctorVanSelectionScreen extends StatefulWidget {
  const DoctorVanSelectionScreen({super.key});

  @override
  State<DoctorVanSelectionScreen> createState() =>
      _DoctorVanSelectionScreenState();
}

class _DoctorVanSelectionScreenState extends State<DoctorVanSelectionScreen> {
  Van? _selectedVan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final vanProvider = context.read<VanProvider>();
      await vanProvider.loadVans();

      // Check if doctor already has a van assigned
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        final assignedVan = await vanProvider.getVanByDoctorId(
          authProvider.user!.id!,
        );
        if (assignedVan != null && mounted) {
          setState(() {
            _selectedVan = assignedVan;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignVan(Van van) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final vanProvider = context.read<VanProvider>();

      if (authProvider.user?.id == null) return;

      // Check if doctor has a linked driver
      if (authProvider.user!.linkedDriverId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You must be linked to a driver before assigning a van',
              ),
            ),
          );
        }
        return;
      }

      // If doctor already has a van, unassign it first
      if (_selectedVan != null && _selectedVan!.id != van.id) {
        await vanProvider.unassignVanFromDoctor(_selectedVan!.id!);
      }

      // Assign van to doctor
      await vanProvider.assignVanToDoctor(van.id!, authProvider.user!.id!);

      setState(() {
        _selectedVan = van;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully assigned van: ${van.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assign van: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unassignVan() async {
    if (_isLoading || _selectedVan == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vanProvider = context.read<VanProvider>();
      await vanProvider.unassignVanFromDoctor(_selectedVan!.id!);

      setState(() {
        _selectedVan = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Van unassigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to unassign van: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vanProvider = context.watch<VanProvider>();
    final availableVans = vanProvider.getAvailableVans();
    final assignedVans = vanProvider.getAssignedVans();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Van'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_selectedVan != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _unassignVan,
              tooltip: 'Unassign Van',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Assignment
                  if (_selectedVan != null) ...[
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Currently Assigned Van',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedVan!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('License: ${_selectedVan!.licensePlate}'),
                            if (_selectedVan!.model != null) ...[
                              const SizedBox(height: 2),
                              Text('Model: ${_selectedVan!.model}'),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              'Capacity: ${_selectedVan!.capacity} passenger(s)',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Available Vans
                  const Text(
                    'Available Vans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (availableVans.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('No vans available for assignment'),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availableVans.length,
                      itemBuilder: (context, index) {
                        final van = availableVans[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              van.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('License: ${van.licensePlate}'),
                                if (van.model != null)
                                  Text('Model: ${van.model}'),
                                Text('Capacity: ${van.capacity} passenger(s)'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _assignVan(van),
                              child: const Text('Assign'),
                            ),
                          ),
                        );
                      },
                    ),

                  // All Vans (for reference)
                  const SizedBox(height: 24),
                  const Text(
                    'All Vans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vanProvider.vans.length,
                    itemBuilder: (context, index) {
                      final van = vanProvider.vans[index];
                      final isAssignedToMe =
                          van.assignedDoctorId ==
                          context.read<AuthProvider>().user?.id;
                      final isAssignedToOther =
                          van.isAssigned && !isAssignedToMe;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isAssignedToMe
                            ? Colors.green.shade50
                            : isAssignedToOther
                            ? Colors.grey.shade100
                            : van.isPartiallyAssigned
                            ? Colors.orange.shade50
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAssignedToMe
                                ? Colors.green
                                : isAssignedToOther
                                ? Colors.grey
                                : van.isPartiallyAssigned
                                ? Colors.orange
                                : Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            van.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAssignedToMe
                                  ? Colors.green.shade800
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('License: ${van.licensePlate}'),
                              Text('Status: ${van.status}'),
                              if (van.model != null)
                                Text('Model: ${van.model}'),
                              if (isAssignedToMe) const Text('Assigned to you'),
                              if (isAssignedToOther)
                                const Text('Assigned to another doctor'),
                              if (van.isPartiallyAssigned &&
                                  !isAssignedToMe &&
                                  !isAssignedToOther)
                                Text(
                                  van.assignedDoctorId != null
                                      ? 'Waiting for driver assignment'
                                      : 'Waiting for doctor assignment',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: isAssignedToMe
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : van.isAvailable || van.isPartiallyAssigned
                              ? ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _assignVan(van),
                                  child: Text(
                                    van.isPartiallyAssigned
                                        ? 'Complete Assignment'
                                        : 'Assign',
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

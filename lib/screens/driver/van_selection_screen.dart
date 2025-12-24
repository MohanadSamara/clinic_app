import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/van_provider.dart';
import '../../models/van.dart';
import '../../models/user.dart';
import '../../translations.dart';

class DriverVanSelectionScreen extends StatefulWidget {
  const DriverVanSelectionScreen({super.key});

  @override
  State<DriverVanSelectionScreen> createState() =>
      _DriverVanSelectionScreenState();
}

class _DriverVanSelectionScreenState extends State<DriverVanSelectionScreen> {
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

      // Check if driver already has a van assigned
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        final assignedVan = await vanProvider.getVanByDriverId(
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

      // Check if driver has a linked doctor
      if (authProvider.user!.linkedDoctorId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('youMustBeLinkedToADoctor'))),
          );
        }
        return;
      }

      // If driver already has a van, unassign it first
      if (_selectedVan != null && _selectedVan!.id != van.id) {
        await vanProvider.unassignVanFromDriver(_selectedVan!.id!);
      }

      // Assign van to driver
      await vanProvider.assignVanToDriver(van.id!, authProvider.user!.id!);

      setState(() {
        _selectedVan = van;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'successfullyAssignedVan',
                args: {'vanName': van.name},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('failedToAssignVan', args: {'error': e.toString()}),
            ),
          ),
        );
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
      await vanProvider.unassignVanFromDriver(_selectedVan!.id!);

      setState(() {
        _selectedVan = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('vanUnassignedSuccessfully'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('failedToUnassignVan', args: {'error': e.toString()}),
            ),
          ),
        );
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
        title: Text(context.tr('selectVan')),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_selectedVan != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _unassignVan,
              tooltip: context.tr('unassignVan'),
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
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  context.tr('currentlyAssignedVan'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
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
                            Text(
                              '${context.tr('license')}: ${_selectedVan!.licensePlate}',
                            ),
                            if (_selectedVan!.model != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${context.tr('model')}: ${_selectedVan!.model}',
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '${context.tr('capacity')}: ${_selectedVan!.capacity} ${context.tr('passengers')}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Available Vans
                  Text(
                    context.tr('availableVans'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (availableVans.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            context.tr('noVansAvailableForAssignment'),
                          ),
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
                                Text(
                                  '${context.tr('license')}: ${van.licensePlate}',
                                ),
                                if (van.model != null)
                                  Text('${context.tr('model')}: ${van.model}'),
                                Text(
                                  '${context.tr('capacity')}: ${van.capacity} ${context.tr('passengers')}',
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _assignVan(van),
                              child: Text(context.tr('assign')),
                            ),
                          ),
                        );
                      },
                    ),

                  // All Vans (for reference)
                  const SizedBox(height: 24),
                  Text(
                    context.tr('allVans'),
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
                          van.assignedDriverId ==
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
                              Text(
                                '${context.tr('license')}: ${van.licensePlate}',
                              ),
                              Text('${context.tr('status')}: ${van.status}'),
                              if (van.model != null)
                                Text('${context.tr('model')}: ${van.model}'),
                              if (isAssignedToMe)
                                Text(context.tr('assignedToYou')),
                              if (isAssignedToOther)
                                Text(context.tr('assignedToAnotherDriver')),
                              if (van.isPartiallyAssigned &&
                                  !isAssignedToMe &&
                                  !isAssignedToOther)
                                Text(
                                  van.assignedDriverId != null
                                      ? context.tr('waitingForDoctorAssignment')
                                      : context.tr(
                                          'waitingForDriverAssignment',
                                        ),
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
                                        ? context.tr('completeAssignment')
                                        : context.tr('assign'),
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

// lib/screens/owner/pet_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pet.dart';
import '../../theme/app_theme.dart';
import '../../components/ui_kit.dart';
import 'medical_history_screen.dart';

class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  State<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user != null && user.id != null) {
        context.read<PetProvider>().loadPets(ownerId: user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add new pet',
            onPressed: () => _showAddPetDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPetDialog(context),
        tooltip: 'Add new pet',
        child: const Icon(Icons.add),
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.pets.isEmpty) {
            return EmptyState(
              icon: Icons.pets,
              title: 'No pets registered yet',
              message:
                  'Add your pets to book appointments and manage their care',
              actionLabel: 'Add Your First Pet',
              onAction: () => _showAddPetDialog(context),
            );
          }

          return Column(
            children: [
              SectionHeader(
                title: 'My Pets',
                subtitle: 'Tap a pet to view or update its details',
              ),
              // Header with pet count and add button hint
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, -10 * (1 - value)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Row(
                          children: [
                            Text(
                              '${petProvider.pets.length} pet${petProvider.pets.length == 1 ? '' : 's'} registered',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(178),
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showAddPetDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Pet'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.padding,
                    vertical: 16,
                  ),
                  itemCount: petProvider.pets.length,
                  itemBuilder: (context, index) {
                    final pet = petProvider.pets[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, animationValue, child) {
                        return Transform.translate(
                          offset: Offset(50 * (1 - animationValue), 0),
                          child: Opacity(
                            opacity: animationValue,
                            child: _PetCard(
                              pet: pet,
                              onEdit: () => _showEditPetDialog(context, pet),
                              onDelete: () =>
                                  _showDeleteConfirmation(context, pet),
                              onViewMedicalHistory: () =>
                                  _navigateToMedicalHistory(context, pet),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEditPetDialog(),
    );
  }

  void _showEditPetDialog(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => _AddEditPetDialog(pet: pet),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (pet.id != null) {
                await context.read<PetProvider>().deletePet(pet.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${pet.name} deleted successfully')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToMedicalHistory(BuildContext context, Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MedicalHistoryScreen(pet: pet)),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewMedicalHistory;

  const _PetCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
    required this.onViewMedicalHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    pet.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pet.species}${pet.breed != null ? ' - ${pet.breed}' : ''}',
                      ),
                      Text(pet.ageDisplay),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pet.species,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(77),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ID: ${pet.serialNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      if (pet.medicalHistorySummary != null &&
                          pet.medicalHistorySummary!.isNotEmpty)
                        Text(
                          'Medical: ${pet.medicalHistorySummary}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(153),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'medical':
                        onViewMedicalHistory();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'medical',
                      child: Text('Medical History'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (pet.notes != null && pet.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${pet.notes}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddEditPetDialog extends StatefulWidget {
  final Pet? pet;

  const _AddEditPetDialog({this.pet});

  @override
  State<_AddEditPetDialog> createState() => _AddEditPetDialogState();
}

class _AddEditPetDialogState extends State<_AddEditPetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _dobController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _speciesController.text = widget.pet!.species;
      _breedController.text = widget.pet!.breed ?? '';
      _dobController.text = widget.pet!.dob ?? '';
      _notesController.text = widget.pet!.notes ?? '';
      _medicalHistoryController.text = widget.pet!.medicalHistorySummary ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    return AlertDialog(
      title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _speciesController.text.isEmpty
                    ? null
                    : _speciesController.text,
                decoration: const InputDecoration(labelText: 'Species'),
                items: const [
                  DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                  DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                  DropdownMenuItem(value: 'Bird', child: Text('Bird')),
                  DropdownMenuItem(value: 'Rabbit', child: Text('Rabbit')),
                  DropdownMenuItem(value: 'Hamster', child: Text('Hamster')),
                  DropdownMenuItem(value: 'Fish', child: Text('Fish')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _speciesController.text = value ?? '';
                  });
                },
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please select species' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Pet Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter pet name' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed (Optional)',
                ),
              ),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dobController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                maxLines: 3,
              ),
              TextFormField(
                controller: _medicalHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Medical History Summary (Optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              if (user == null || user.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not authenticated')),
                );
                return;
              }

              final pet = widget.pet == null
                  ? Pet.create(
                      ownerId: user.id!,
                      name: _nameController.text,
                      species: _speciesController.text,
                      breed: _breedController.text.isEmpty
                          ? null
                          : _breedController.text,
                      dob: _dobController.text.isEmpty
                          ? null
                          : _dobController.text,
                      notes: _notesController.text.isEmpty
                          ? null
                          : _notesController.text,
                      medicalHistorySummary:
                          _medicalHistoryController.text.isEmpty
                          ? null
                          : _medicalHistoryController.text,
                    )
                  : widget.pet!.copyWith(
                      name: _nameController.text,
                      species: _speciesController.text,
                      breed: _breedController.text.isEmpty
                          ? null
                          : _breedController.text,
                      dob: _dobController.text.isEmpty
                          ? null
                          : _dobController.text,
                      notes: _notesController.text.isEmpty
                          ? null
                          : _notesController.text,
                      medicalHistorySummary:
                          _medicalHistoryController.text.isEmpty
                          ? null
                          : _medicalHistoryController.text,
                    );

              final linkedDoctorId = authProvider.user?.linkedDoctorId;
              final success = widget.pet == null
                  ? await context.read<PetProvider>().addPet(
                      pet,
                      doctorId: linkedDoctorId,
                    )
                  : await context.read<PetProvider>().updatePet(pet);

              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.pet == null
                          ? 'Pet added successfully! Serial Number: ${pet.serialNumber}'
                          : 'Pet updated successfully',
                    ),
                    duration: widget.pet == null
                        ? const Duration(seconds: 5)
                        : const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
          child: Text(widget.pet == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _dobController.dispose();
    _notesController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }
}

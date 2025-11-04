// lib/screens/owner/pet_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pet.dart';

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
            onPressed: () => _showAddPetDialog(context),
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No pets registered yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddPetDialog(context),
                    child: const Text('Add Your First Pet'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: petProvider.pets.length,
            itemBuilder: (context, index) {
              final pet = petProvider.pets[index];
              return _PetCard(
                pet: pet,
                onEdit: () => _showEditPetDialog(context, pet),
                onDelete: () => _showDeleteConfirmation(context, pet),
                onViewMedicalHistory: () =>
                    _navigateToMedicalHistory(context, pet),
              );
            },
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    pet.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
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
                      Text('${pet.species} ${pet.breed ?? ''}'),
                      if (pet.dob != null) Text('Born: ${pet.dob}'),
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
                style: TextStyle(color: Colors.grey[600]),
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

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _speciesController.text = widget.pet!.species;
      _breedController.text = widget.pet!.breed ?? '';
      _dobController.text = widget.pet!.dob ?? '';
      _notesController.text = widget.pet!.notes ?? '';
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

              final pet = Pet(
                id: widget.pet?.id,
                ownerId: user.id!,
                name: _nameController.text,
                species: _speciesController.text,
                breed: _breedController.text.isEmpty
                    ? null
                    : _breedController.text,
                dob: _dobController.text.isEmpty ? null : _dobController.text,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              );

              final success = widget.pet == null
                  ? await context.read<PetProvider>().addPet(pet)
                  : await context.read<PetProvider>().updatePet(pet);

              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.pet == null
                          ? 'Pet added successfully'
                          : 'Pet updated successfully',
                    ),
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
    super.dispose();
  }
}

// Placeholder for Medical History Screen
class MedicalHistoryScreen extends StatelessWidget {
  final Pet pet;

  const MedicalHistoryScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${pet.name} - Medical History')),
      body: const Center(child: Text('Medical History Screen - Coming Soon')),
    );
  }
}

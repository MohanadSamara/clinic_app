import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  List<User> _doctors = [];
  bool _isLoading = true;
  User? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final dbHelper = DBHelper.instance;
      final doctorsData = await dbHelper.getAllUsers(role: 'doctor');
      final doctors = doctorsData.map((data) => User.fromMap(data)).toList();

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDoctor(User doctor) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id == null) return;

    try {
      // Update the driver's linked_doctor_id
      await DBHelper.instance.updateUser(authProvider.user!.id!, {
        'linked_doctor_id': doctor.id,
      });

      // Update the doctor's linked_driver_id
      await DBHelper.instance.updateUser(doctor.id!, {
        'linked_driver_id': authProvider.user!.id,
      });

      // Update the auth provider's user
      final updatedUser = authProvider.user!.copyWith(
        linkedDoctorId: doctor.id,
      );

      setState(() {
        _selectedDoctor = doctor;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully linked with Dr. ${doctor.name}')),
      );

      // Navigate back to dashboard
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error linking with doctor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to link with doctor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Doctor'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
          ? const Center(child: Text('No doctors available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      'Dr. ${doctor.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.email),
                        if (doctor.phone != null) Text(doctor.phone!),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _selectDoctor(doctor),
                      child: const Text('Select'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

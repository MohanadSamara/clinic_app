// lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'role_based_home.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String name;
  final String email;
  final String provider;
  final String providerId;

  const RoleSelectionScreen({
    super.key,
    required this.name,
    required this.email,
    required this.provider,
    required this.providerId,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _loading = false;

  final List<Map<String, String>> _roles = [
    {
      'value': 'owner',
      'label': 'Pet Owner',
      'description': 'Book appointments and manage your pets',
    },
    {
      'value': 'doctor',
      'label': 'Veterinarian',
      'description': 'Manage appointments and medical records',
    },
    {
      'value': 'driver',
      'label': 'Driver',
      'description': 'Handle transportation services',
    },
    {
      'value': 'admin',
      'label': 'Administrator',
      'description': 'Manage users and system settings',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.name}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select your role to continue:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<String>(
                      title: Text(role['label']!),
                      subtitle: Text(role['description']!),
                      value: role['value']!,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _selectedRole != null
                          ? _completeRegistration
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (_selectedRole == null) return;

    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.completeSocialRegistration(
        name: widget.name,
        email: widget.email,
        role: _selectedRole!,
        provider: widget.provider,
        providerId: widget.providerId,
      );

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleBasedHome()),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

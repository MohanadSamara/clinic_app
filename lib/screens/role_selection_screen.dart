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
  String? _selectedArea;
  bool _loading = false;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Select Your Role'),
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.name}!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your role to continue:',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  return Card(
                    color: colorScheme.surface,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(
                        role['label']!,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        role['description']!,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      leading: Radio<String>(
                        value: role['value']!,
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Area selection for doctors and drivers
            if (_selectedRole == 'doctor' || _selectedRole == 'driver') ...[
              const SizedBox(height: 24),
              Text(
                'Service Area',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the area where you will provide services:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: InputDecoration(
                  labelText: 'Service Area *',
                  hintText: 'Select your service area',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
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
                validator:
                    (_selectedRole == 'doctor' || _selectedRole == 'driver')
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a service area';
                        }
                        return null;
                      }
                    : null,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _loading
                  ? Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed:
                          (_selectedRole != null &&
                              ((_selectedRole != 'doctor' &&
                                      _selectedRole != 'driver') ||
                                  _selectedArea != null))
                          ? _completeRegistration
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Continue'),
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
        area: _selectedArea,
      );

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
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

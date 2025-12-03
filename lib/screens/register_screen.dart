// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'role_based_home.dart';
import 'role_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  String _selectedRole = 'owner';
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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Top area
              Center(
                child: Column(
                  children: [
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's set up your account",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form card
              Card(
                color: colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Form Fields
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pass,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Min 6 characters',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Optional',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          hintText: 'Select your role',
                          prefixIcon: Icon(
                            Icons.work_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Pet Owner'),
                          ),
                          DropdownMenuItem(
                            value: 'doctor',
                            child: Text('Veterinarian'),
                          ),
                          DropdownMenuItem(
                            value: 'driver',
                            child: Text('Driver'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrator'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            // Reset area when role changes
                            if (_selectedRole == 'owner' ||
                                _selectedRole == 'admin') {
                              _selectedArea = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Area selection for doctors and drivers
                      if (_selectedRole == 'doctor' ||
                          _selectedRole == 'driver')
                        DropdownButtonFormField<String>(
                          value: _selectedArea,
                          decoration: InputDecoration(
                            labelText: 'Service Area *',
                            hintText: 'Select your service area',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              color: colorScheme.onSurfaceVariant,
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
                              (_selectedRole == 'doctor' ||
                                  _selectedRole == 'driver')
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a service area';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      const SizedBox(height: 24),

                      // Primary action button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: auth.isLoading || _loading
                            ? Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.onPrimary,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Create Account'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 32),

              // Divider with "Or continue with"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or continue with',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Social buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _googleSignUp,
                      icon: Icon(Icons.g_mobiledata, color: colorScheme.error),
                      label: Text(
                        'Google',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.15),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _facebookSignUp,
                      icon: Icon(Icons.facebook, color: colorScheme.secondary),
                      label: Text(
                        'Facebook',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.15),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Sign In Link - secondary action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign In',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Validation
    if (_name.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_email.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_email.text.trim())) {
      _showError('Please enter a valid email address');
      return;
    }
    if (_pass.text.length < 6) {
      _showError('Password must be at least 6 characters long');
      return;
    }
    if ((_selectedRole == 'doctor' || _selectedRole == 'driver') &&
        (_selectedArea == null || _selectedArea!.isEmpty)) {
      _showError('Please select a service area for your role');
      return;
    }

    setState(() => _loading = true);
    try {
      await auth.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        role: _selectedRole,
        area: _selectedArea,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleBasedHome()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _googleSignUp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _loading = true);
    try {
      await auth.signInWithGoogle();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (auth.needsRoleSelection) {
            final pending = auth.pendingSocialUser!;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RoleSelectionScreen(
                  name: pending['name'],
                  email: pending['email'],
                  provider: pending['provider'],
                  providerId: pending['providerId'],
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleBasedHome()),
            );
          }
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _facebookSignUp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _loading = true);
    try {
      await auth.signInWithFacebook();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (auth.needsRoleSelection) {
            final pending = auth.pendingSocialUser!;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RoleSelectionScreen(
                  name: pending['name'],
                  email: pending['email'],
                  provider: pending['provider'],
                  providerId: pending['providerId'],
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleBasedHome()),
            );
          }
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

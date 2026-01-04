// lib/screens/doctor/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../components/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../../translations.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
  bool _showPasswordFields = false;
  String? _errorMessage;

  // Doctor-specific fields (these would be stored in a separate doctor profile table in production)
  String _specialization = '';
  String _licenseNumber = '';
  String _experience = '';
  String _bio = '';

  @override
  void initState() {
    super.initState();
    // Load doctor-specific data (simulated for now)
    _loadDoctorProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _selectedArea = user.area;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _licenseNumberController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    // In production, this would load from a doctor_profiles table
    // For now, we'll simulate loading doctor-specific data
    setState(() {
      _specialization = 'Veterinary Medicine'; // Default
      _licenseNumber = 'VET-2024-001'; // Default
      _experience = '5'; // Default years
      _bio =
          'Experienced veterinarian specializing in small animal care.'; // Default
    });

    _specializationController.text = _specialization;
    _licenseNumberController.text = _licenseNumber;
    _experienceController.text = _experience;
    _bioController.text = _bio;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Check if password change is requested
      if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('New passwords do not match');
        }
      }

      // Update basic user profile
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        area: _selectedArea,
        currentPassword:
            _showPasswordFields && _currentPasswordController.text.isNotEmpty
            ? _currentPasswordController.text
            : null,
        newPassword:
            _showPasswordFields && _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null,
      );

      // Update doctor-specific profile (in production, save to doctor_profiles table)
      await _updateDoctorProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('profileUpdatedSuccessfully'))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateDoctorProfile() async {
    // In production, this would update the doctor_profiles table
    // For now, we'll just simulate the update
    _specialization = _specializationController.text.trim();
    _licenseNumber = _licenseNumberController.text.trim();
    _experience = _experienceController.text.trim();
    _bio = _bioController.text.trim();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('doctorProfile')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, animationValue, child) {
          return Opacity(
            opacity: animationValue,
            child: Transform.translate(
              offset: Offset(0.0, 20.0 * (1.0 - animationValue)),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, headerValue, child) {
                          return Opacity(
                            opacity: headerValue,
                            child: Transform.translate(
                              offset: Offset(-30.0 * (1.0 - headerValue), 0.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('editDoctorProfile'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr(
                                      'updateYourProfessionalInformation',
                                    ),
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Profile Picture Section
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, avatarValue, child) {
                          return Opacity(
                            opacity: avatarValue,
                            child: Transform.translate(
                              offset: Offset(30.0 * (1.0 - avatarValue), 0.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      child: Icon(
                                        Icons.local_hospital,
                                        size: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        // TODO: Implement profile picture upload
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.tr(
                                                'profilePictureUploadComingSoon',
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.camera_alt),
                                      label: Text(context.tr('changePhoto')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Personal Information Section
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, personalValue, child) {
                          return Opacity(
                            opacity: personalValue,
                            child: Transform.translate(
                              offset: Offset(
                                (-30 * (1 - personalValue)).toDouble(),
                                0,
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.padding),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('personalInformation'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Name Field
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: context.tr('fullName'),
                                          prefixIcon: const Icon(Icons.person),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context.tr('nameRequired');
                                          }
                                          if (value.trim().length < 2) {
                                            return context.tr('nameMinLength');
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Email Field (Read-only)
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          labelText: context.tr('emailAddress'),
                                          prefixIcon: const Icon(Icons.email),
                                        ),
                                        readOnly: true,
                                        enabled: false,
                                      ),
                                      const SizedBox(height: 16),

                                      // Phone Field
                                      TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          labelText: context.tr('phoneNumber'),
                                          prefixIcon: const Icon(Icons.phone),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context.tr(
                                              'phoneRequiredForDoctors',
                                            );
                                          }
                                          final phoneRegExp = RegExp(
                                            r'^\+?[\d\s\-\(\)]+$',
                                          );
                                          if (!phoneRegExp.hasMatch(value)) {
                                            return context.tr(
                                              'enterValidPhoneNumber',
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Professional Information Section
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, professionalValue, child) {
                          return Opacity(
                            opacity: professionalValue,
                            child: Transform.translate(
                              offset: Offset(
                                (30 * (1 - professionalValue)).toDouble(),
                                0,
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('professionalInformation'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Specialization Field
                                      TextFormField(
                                        controller: _specializationController,
                                        decoration: InputDecoration(
                                          labelText: context.tr(
                                            'specialization',
                                          ),
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
                                            Icons.medical_services,
                                          ),
                                          hintText: context.tr(
                                            'specializationHint',
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context.tr(
                                              'specializationRequired',
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // License Number Field
                                      TextFormField(
                                        controller: _licenseNumberController,
                                        decoration: InputDecoration(
                                          labelText: context.tr(
                                            'licenseNumber',
                                          ),
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.badge),
                                          hintText: context.tr(
                                            'licenseNumberHint',
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context.tr(
                                              'licenseRequired',
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Years of Experience Field
                                      TextFormField(
                                        controller: _experienceController,
                                        decoration: InputDecoration(
                                          labelText: context.tr(
                                            'yearsOfExperience',
                                          ),
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
                                            Icons.timeline,
                                          ),
                                          hintText: context.tr('yearsHint'),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context.tr(
                                              'experienceRequired',
                                            );
                                          }
                                          final years = int.tryParse(value);
                                          if (years == null || years < 0) {
                                            return context.tr(
                                              'enterValidNumber',
                                            );
                                          }
                                          if (years > 50) {
                                            return context.tr(
                                              'enterRealisticYears',
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Area Field
                                      DropdownButtonFormField<String>(
                                        value: _selectedArea,
                                        decoration: InputDecoration(
                                          labelText: context.tr('serviceArea'),
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                          ),
                                          hintText: context.tr(
                                            'selectServiceArea',
                                          ),
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
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return context.tr(
                                              'serviceAreaRequired',
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Bio Field
                                      TextFormField(
                                        controller: _bioController,
                                        decoration: InputDecoration(
                                          labelText: context.tr(
                                            'professionalBio',
                                          ),
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
                                            Icons.description,
                                          ),
                                          hintText: context.tr('bioHint'),
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context.tr('bioRequired');
                                          }
                                          if (value.trim().length < 10) {
                                            return context.tr('bioMinLength');
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Password Change Section
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, passwordValue, child) {
                          return Opacity(
                            opacity: passwordValue,
                            child: Transform.translate(
                              offset: Offset(
                                (-30 * (1 - passwordValue)).toDouble(),
                                0,
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              context.tr('changePassword'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                          Switch(
                                            value: _showPasswordFields,
                                            onChanged: (value) {
                                              setState(() {
                                                _showPasswordFields = value;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('enablePasswordChange'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),

                                      if (_showPasswordFields) ...[
                                        const SizedBox(height: 24),
                                        TextFormField(
                                          controller:
                                              _currentPasswordController,
                                          decoration: InputDecoration(
                                            labelText: context.tr(
                                              'currentPassword',
                                            ),
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.lock),
                                          ),
                                          obscureText: true,
                                          validator: (value) {
                                            if (_showPasswordFields) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return context.tr(
                                                  'currentPasswordRequired',
                                                );
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _newPasswordController,
                                          decoration: InputDecoration(
                                            labelText: context.tr(
                                              'newPassword',
                                            ),
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                          ),
                                          obscureText: true,
                                          validator: (value) {
                                            if (_showPasswordFields) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return context.tr(
                                                  'newPasswordRequired',
                                                );
                                              }
                                              if (value.length < 6) {
                                                return context.tr(
                                                  'passwordMinLength',
                                                );
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          decoration: InputDecoration(
                                            labelText: context.tr(
                                              'confirmNewPassword',
                                            ),
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                          ),
                                          obscureText: true,
                                          validator: (value) {
                                            if (_showPasswordFields) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return context.tr(
                                                  'confirmPasswordRequired',
                                                );
                                              }
                                              if (value !=
                                                  _newPasswordController.text) {
                                                return context.tr(
                                                  'passwordsDoNotMatch',
                                                );
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Buttons
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1100),
                        builder: (context, buttonValue, child) {
                          return Opacity(
                            opacity: buttonValue,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                (20 * (1 - buttonValue)).toDouble(),
                              ),
                              child: Column(
                                children: [
                                  PrimaryButton(
                                    label: context.tr('saveChanges'),
                                    onPressed: _isLoading
                                        ? null
                                        : _updateProfile,
                                    isLoading: _isLoading,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('profileInfoHelp'),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: Text(context.tr('cancel')),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

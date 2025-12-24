// lib/screens/driver/driver_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../models/location_data.dart';
import '../../theme/app_theme.dart';
import '../../components/ui_kit.dart';
import '../../translations.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedArea;

  List<String> get _ammanDistricts {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    return AmmanDistricts.allDistricts.map((district) {
      return isArabic ? district.arabicName : '${district.name} District';
    }).toList();
  }

  // Get the display value for the selected area
  String? get _selectedAreaDisplay {
    if (_selectedArea == null) return null;

    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    final district = AmmanDistricts.getDistrictByName(_selectedArea!);
    if (district != null) {
      return isArabic ? district.arabicName : '${district.name} District';
    }

    return _selectedArea;
  }

  bool _isLoading = false;
  bool _showPasswordFields = false;
  String? _errorMessage;

  // Driver-specific fields
  String _licenseNumber = '';
  String _vehicleType = '';
  String _experience = '';
  String _bio = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _selectedArea = user.area;
    }

    // Load driver-specific data (simulated for now)
    _loadDriverProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _vehicleTypeController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    // In production, this would load from a driver_profiles table
    // For now, we'll simulate loading driver-specific data
    setState(() {
      _licenseNumber = 'DRV-2024-001'; // Default
      _vehicleType = 'Van'; // Default
      _experience = '3'; // Default years
      _bio =
          'Experienced driver specializing in veterinary service transportation.'; // Default
    });

    _licenseNumberController.text = _licenseNumber;
    _vehicleTypeController.text = _vehicleType;
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
          throw Exception(context.tr('passwordsDoNotMatch'));
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

      // Update driver-specific profile (in production, save to driver_profiles table)
      await _updateDriverProfile();

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

  Future<void> _updateDriverProfile() async {
    // In production, this would update the driver_profiles table
    // For now, we'll just simulate the update
    _licenseNumber = _licenseNumberController.text.trim();
    _vehicleType = _vehicleTypeController.text.trim();
    _experience = _experienceController.text.trim();
    _bio = _bioController.text.trim();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('driverProfile')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                context.tr('editDriverProfile'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('updateYourProfessionalInformation'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.drive_eta,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement profile picture upload
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('profilePictureUploadComingSoon'),
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
              const SizedBox(height: 32),

              // Personal Information Section
              Card(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('personalInformation'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: context.tr('fullName'),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                          prefixIcon: Icon(Icons.email),
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
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('phoneRequiredForDrivers');
                          }
                          final phoneRegExp = RegExp(r'^\+?[\d\s\-\(\)]+$');
                          if (!phoneRegExp.hasMatch(value)) {
                            return context.tr('invalidPhoneNumber');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Professional Information Section
              Card(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('professionalInformation'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // License Number Field
                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: InputDecoration(
                          labelText: context.tr('driverLicenseNumber'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                          hintText: context.tr(
                            'professionalDriverLicenseNumber',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('licenseRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Type Field
                      TextFormField(
                        controller: _vehicleTypeController,
                        decoration: InputDecoration(
                          labelText: context.tr('vehicleType'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                          hintText: context.tr('vehicleTypeHint'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('vehicleTypeRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Service Area Field
                      DropdownButtonFormField<String>(
                        value: _selectedAreaDisplay,
                        decoration: InputDecoration(
                          labelText: context.tr('serviceArea'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          hintText: context.tr('selectServiceArea'),
                        ),
                        items: _ammanDistricts.map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final locale = Localizations.localeOf(context);
                            final isArabic = locale.languageCode == 'ar';

                            // Find the district and store the English name
                            final district = AmmanDistricts.allDistricts
                                .firstWhere(
                                  (d) => isArabic
                                      ? d.arabicName == value
                                      : '${d.name} District' == value,
                                  orElse: () =>
                                      AmmanDistricts.allDistricts.first,
                                );

                            setState(() {
                              _selectedArea = district.name;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('serviceAreaRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Years of Experience Field
                      TextFormField(
                        controller: _experienceController,
                        decoration: InputDecoration(
                          labelText: context.tr('yearsOfExperience'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timeline),
                          hintText: context.tr('yearsHint'),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('experienceRequired');
                          }
                          final years = int.tryParse(value);
                          if (years == null || years < 0) {
                            return context.tr('enterValidNumber');
                          }
                          if (years > 50) {
                            return context.tr('enterRealisticYears');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bio Field
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: context.tr('professionalBio'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: context.tr('bioHint'),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
              const SizedBox(height: 24),

              // Password Change Section
              Card(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('changePassword'),
                              style: Theme.of(context).textTheme.titleLarge
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
                        context.tr('enableToChangeYourPassword'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),

                      if (_showPasswordFields) ...[
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: InputDecoration(
                            labelText: context.tr('currentPassword'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (_showPasswordFields) {
                              if (value == null || value.isEmpty) {
                                return context.tr('currentPasswordRequired');
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: InputDecoration(
                            labelText: context.tr('newPassword'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (_showPasswordFields) {
                              if (value == null || value.isEmpty) {
                                return context.tr('newPasswordRequired');
                              }
                              if (value.length < 6) {
                                return context.tr('passwordMinLength');
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: context.tr('confirmNewPassword'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (_showPasswordFields) {
                              if (value == null || value.isEmpty) {
                                return context.tr('confirmPasswordRequired');
                              }
                              if (value != _newPasswordController.text) {
                                return context.tr('passwordsDoNotMatch');
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
              PrimaryButton(
                label: context.tr('saveChanges'),
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('profileInfoHelp'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(context.tr('cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

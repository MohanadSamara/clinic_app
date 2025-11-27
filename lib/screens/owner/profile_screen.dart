// lib/screens/owner/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../notification_preferences_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPasswordFields = false;
  String? _errorMessage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Account settings
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'en';
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      if (user.profileImage != null && user.profileImage!.isNotEmpty) {
        _profileImage = File(user.profileImage!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        // For password change, we'd need to verify current password
        // This is a simplified version - in production, verify current password
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('New passwords do not match');
        }
      }

      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        currentPassword:
            _showPasswordFields && _currentPasswordController.text.isNotEmpty
            ? _currentPasswordController.text
            : null,
        newPassword:
            _showPasswordFields && _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null,
        profileImage: _profileImage?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await authProvider.logout();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/login');
          });
        }
      } catch (e) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
          });
        }
      }
    }
  }

  Future<void> _exportData() async {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export feature coming soon')),
    );
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // TODO: Implement account deletion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deletion feature coming soon')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
              offset: Offset(0, 20 * (1 - animationValue)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                              offset: Offset(-30 * (1 - headerValue), 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Profile',
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
                                    'Update your personal information',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
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
                              offset: Offset(30 * (1 - avatarValue), 0),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      backgroundImage: _profileImage != null
                                          ? FileImage(_profileImage!)
                                          : null,
                                      child: _profileImage == null
                                          ? Text(
                                              _nameController.text.isNotEmpty
                                                  ? _nameController.text
                                                        .substring(0, 1)
                                                        .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: 32,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Change Photo'),
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
                        builder: (context, formValue, child) {
                          return Opacity(
                            opacity: formValue,
                            child: Transform.translate(
                              offset: Offset(-30 * (1 - formValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
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
                                        'Personal Information',
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
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Name is required';
                                          }
                                          if (value.trim().length < 2) {
                                            return 'Name must be at least 2 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Email Field (Read-only for now)
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email Address',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.email),
                                        ),
                                        readOnly: true,
                                        enabled: false,
                                      ),
                                      const SizedBox(height: 16),

                                      // Phone Field
                                      TextFormField(
                                        controller: _phoneController,
                                        decoration: const InputDecoration(
                                          labelText: 'Phone Number (Optional)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.phone),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            // Basic phone validation
                                            final phoneRegExp = RegExp(
                                              r'^\+?[\d\s\-\(\)]+$',
                                            );
                                            if (!phoneRegExp.hasMatch(value)) {
                                              return 'Please enter a valid phone number';
                                            }
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
                        duration: const Duration(milliseconds: 900),
                        builder: (context, passwordValue, child) {
                          return Opacity(
                            opacity: passwordValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - passwordValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
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
                                              'Change Password',
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
                                        'Enable to change your password',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),

                                      if (_showPasswordFields) ...[
                                        const SizedBox(height: 24),
                                        TextFormField(
                                          controller:
                                              _currentPasswordController,
                                          decoration: const InputDecoration(
                                            labelText: 'Current Password',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.lock),
                                          ),
                                          obscureText: true,
                                          validator: (value) {
                                            if (_showPasswordFields) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Current password is required';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _newPasswordController,
                                          decoration: const InputDecoration(
                                            labelText: 'New Password',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                            ),
                                          ),
                                          obscureText: true,
                                          validator: (value) {
                                            if (_showPasswordFields) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'New password is required';
                                              }
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          decoration: const InputDecoration(
                                            labelText: 'Confirm New Password',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                            ),
                                          ),
                                          obscureText: true,
                                          validator: (value) {
                                            if (_showPasswordFields) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please confirm your new password';
                                              }
                                              if (value !=
                                                  _newPasswordController.text) {
                                                return 'Passwords do not match';
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
                      const SizedBox(height: 24),

                      // Account Settings Section
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, settingsValue, child) {
                          return Opacity(
                            opacity: settingsValue,
                            child: Transform.translate(
                              offset: Offset(-30 * (1 - settingsValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
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
                                        'Account Settings',
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

                                      // Notifications Toggle
                                      SwitchListTile(
                                        title: const Text('Push Notifications'),
                                        subtitle: const Text(
                                          'Receive appointment reminders and updates',
                                        ),
                                        value: _notificationsEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _notificationsEnabled = value;
                                          });
                                        },
                                      ),
                                      const Divider(),

                                      // Language Selection
                                      ListTile(
                                        title: const Text('Language'),
                                        subtitle: Text(
                                          _selectedLanguage == 'en'
                                              ? 'English'
                                              : 'العربية',
                                        ),
                                        trailing: DropdownButton<String>(
                                          value: _selectedLanguage,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'en',
                                              child: Text('English'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'ar',
                                              child: Text('العربية'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedLanguage = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const Divider(),

                                      // Biometric Authentication
                                      SwitchListTile(
                                        title: const Text('Biometric Login'),
                                        subtitle: const Text(
                                          'Use fingerprint or face unlock',
                                        ),
                                        value: _biometricEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _biometricEnabled = value;
                                          });
                                        },
                                      ),
                                      const Divider(),

                                      // Notification Preferences
                                      ListTile(
                                        title: const Text(
                                          'Notification Preferences',
                                        ),
                                        subtitle: const Text(
                                          'Manage reminders and alerts',
                                        ),
                                        trailing: const Icon(
                                          Icons.notifications,
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NotificationPreferencesScreen(),
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
                      const SizedBox(height: 24),

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
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, buttonValue, child) {
                          return Opacity(
                            opacity: buttonValue,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - buttonValue)),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save Changes'),
                                    ),
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
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Danger Zone - Logout and Account Deletion
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1100),
                        builder: (context, dangerValue, child) {
                          return Opacity(
                            opacity: dangerValue,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - dangerValue)),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.red.shade200,
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
                                        'Account Actions',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Manage your account security and data',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 24),

                                      // Logout Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _logout,
                                          icon: const Icon(
                                            Icons.logout,
                                            color: Colors.red,
                                          ),
                                          label: const Text('Logout'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Export Data Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _exportData,
                                          icon: const Icon(
                                            Icons.download,
                                            color: Colors.blue,
                                          ),
                                          label: const Text('Export My Data'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.blue,
                                            ),
                                            foregroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Delete Account Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _deleteAccount,
                                          icon: const Icon(
                                            Icons.delete_forever,
                                          ),
                                          label: const Text('Delete Account'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

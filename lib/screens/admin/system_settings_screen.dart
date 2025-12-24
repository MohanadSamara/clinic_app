import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  final List<Map<String, dynamic>> _settings = [
    {
      'key': 'clinic_name',
      'label': 'Clinic Name',
      'type': 'text',
      'default': 'VetCare Clinic',
    },
    {
      'key': 'clinic_address',
      'label': 'Clinic Address',
      'type': 'text',
      'default': '',
    },
    {
      'key': 'clinic_phone',
      'label': 'Clinic Phone',
      'type': 'text',
      'default': '',
    },
    {
      'key': 'clinic_email',
      'label': 'Clinic Email',
      'type': 'text',
      'default': '',
    },
    {
      'key': 'working_hours_start',
      'label': 'Working Hours Start',
      'type': 'time',
      'default': '08:00',
    },
    {
      'key': 'working_hours_end',
      'label': 'Working Hours End',
      'type': 'time',
      'default': '18:00',
    },
    {
      'key': 'emergency_contact',
      'label': 'Emergency Contact',
      'type': 'text',
      'default': '',
    },
    {
      'key': 'max_appointments_per_day',
      'label': 'Max Appointments Per Day',
      'type': 'number',
      'default': '50',
    },
    {
      'key': 'appointment_duration_minutes',
      'label': 'Appointment Duration (minutes)',
      'type': 'number',
      'default': '30',
    },
    {
      'key': 'enable_notifications',
      'label': 'Enable Notifications',
      'type': 'boolean',
      'default': 'true',
    },
    {
      'key': 'enable_emergency_services',
      'label': 'Enable Emergency Services',
      'type': 'boolean',
      'default': 'true',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Delay loading until after the first build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _initializeControllers() {
    for (final setting in _settings) {
      _controllers[setting['key']] = TextEditingController();
    }
  }

  Future<void> _loadSettings() async {
    final adminProvider = context.read<AdminProvider>();
    await adminProvider.loadSystemSettings();

    final currentSettings = adminProvider.systemSettings;
    for (final setting in _settings) {
      final key = setting['key'];
      final value = currentSettings[key] ?? setting['default'];
      _controllers[key]!.text = value.toString();
    }

    setState(() {});
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final adminProvider = context.read<AdminProvider>();
    bool success = true;

    for (final setting in _settings) {
      final key = setting['key'];
      final value = _controllers[key]!.text.trim();
      if (value.isNotEmpty) {
        final result = await adminProvider.updateSystemSetting(key, value);
        if (!result) {
          success = false;
          break;
        }
      }
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save some settings')),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is admin
    if (auth.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to access this page.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clinic Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildSettingsGroup([
                    'clinic_name',
                    'clinic_address',
                    'clinic_phone',
                    'clinic_email',
                  ]),

                  const SizedBox(height: 32),
                  const Text(
                    'Working Hours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildSettingsGroup([
                    'working_hours_start',
                    'working_hours_end',
                  ]),

                  const SizedBox(height: 32),
                  const Text(
                    'Appointment Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildSettingsGroup([
                    'max_appointments_per_day',
                    'appointment_duration_minutes',
                  ]),

                  const SizedBox(height: 32),
                  const Text(
                    'Emergency Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildSettingsGroup(['emergency_contact']),

                  const SizedBox(height: 32),
                  const Text(
                    'System Features',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildSettingsGroup([
                    'enable_notifications',
                    'enable_emergency_services',
                  ]),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: adminProvider.isLoading ? null : _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save All Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSettingsGroup(List<String> keys) {
    final widgets = <Widget>[];

    for (final key in keys) {
      final setting = _settings.firstWhere((s) => s['key'] == key);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSettingField(setting),
        ),
      );
    }

    return widgets;
  }

  Widget _buildSettingField(Map<String, dynamic> setting) {
    final key = setting['key'];
    final label = setting['label'];
    final type = setting['type'];

    switch (type) {
      case 'boolean':
        return SwitchListTile(
          title: Text(label),
          value: _controllers[key]!.text.toLowerCase() == 'true',
          onChanged: (value) {
            setState(() {
              _controllers[key]!.text = value.toString();
            });
          },
        );
      case 'number':
        return TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (int.tryParse(value!) == null) return 'Must be a number';
            return null;
          },
        );
      case 'time':
        return TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(
            labelText: label,
            hintText: 'HH:MM',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
            if (!timeRegex.hasMatch(value!))
              return 'Invalid time format (HH:MM)';
            return null;
          },
        );
      default:
        return TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            return null;
          },
        );
    }
  }
}








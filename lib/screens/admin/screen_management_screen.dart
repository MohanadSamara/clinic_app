import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/screen_configuration_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/screen_configuration.dart';
import '../../translations.dart';

class ScreenManagementScreen extends StatefulWidget {
  const ScreenManagementScreen({super.key});

  @override
  State<ScreenManagementScreen> createState() => _ScreenManagementScreenState();
}

class _ScreenManagementScreenState extends State<ScreenManagementScreen> {
  String _selectedRole = 'admin';
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showDisabledOnly = false;
  bool _isEditing = false;
  ScreenConfiguration? _editingConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfigurations();
    });
  }

  Future<void> _loadConfigurations() async {
    final provider = context.read<ScreenConfigurationProvider>();
    await provider.loadConfigurationsForRole(_selectedRole);
  }

  Future<void> _initializeDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize Default Screens'),
        content: const Text(
          'This will reset all screen configurations to default for all roles. '
          'Any custom configurations will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<ScreenConfigurationProvider>();
      await provider.initializeDefaultConfigurations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default configurations initialized')),
        );
      }
    }
  }

  Future<void> _resetRoleToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset $_selectedRole to Defaults'),
        content: Text(
          'This will reset all screen configurations for $_selectedRole to default. '
          'Any custom configurations for this role will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<ScreenConfigurationProvider>();
      await provider.resetToDefaults(_selectedRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_selectedRole configurations reset to defaults')),
        );
      }
    }
  }

  List<ScreenConfiguration> _filterConfigurations(List<ScreenConfiguration> configs) {
    return configs.where((config) {
      // Category filter
      if (_selectedCategory != 'All' && config.category != _selectedCategory) {
        return false;
      }

      // Disabled only filter
      if (_showDisabledOnly && config.isEnabled) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = config.screenName.toLowerCase().contains(query);
        final matchesDescription = config.screenDescription?.toLowerCase().contains(query) ?? false;
        final matchesScreenId = config.screenId.toLowerCase().contains(query);
        if (!matchesName && !matchesDescription && !matchesScreenId) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (auth.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('accessDenied'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                context.tr('accessDenied'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(context.tr('noPermissionToAccessPage')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetRoleToDefaults,
            tooltip: 'Reset to Defaults',
          ),
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: _initializeDefaults,
            tooltip: 'Initialize All Defaults',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: 'Add Custom Screen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Role selector and filters
          _buildFilterBar(),
          // Content
          Expanded(
            child: Consumer<ScreenConfigurationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadConfigurations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final roleConfigs = provider.getConfigurationsForRole(_selectedRole);
                final filteredConfigs = _filterConfigurations(roleConfigs);

                if (filteredConfigs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.settings_display, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No screens configured for $_selectedRole',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click the + button to add screens or reset to defaults',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _resetRoleToDefaults,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Load Defaults'),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredConfigs.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final config = filteredConfigs[oldIndex];
                    await provider.updateSortOrder(_selectedRole, config.screenId, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final config = filteredConfigs[index];
                    return _buildScreenCard(config, Key(config.id ?? config.screenId));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final provider = context.read<ScreenConfigurationProvider>();
    final categories = ['All', ...provider.availableCategories];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // Role selector
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'admin', label: Text('Admin')),
                    ButtonSegment(value: 'doctor', label: Text('Doctor')),
                    ButtonSegment(value: 'driver', label: Text('Driver')),
                    ButtonSegment(value: 'owner', label: Text('Owner')),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedRole = selected.first;
                    });
                    _loadConfigurations();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search and filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search screens...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Disabled Only'),
                selected: _showDisabledOnly,
                onSelected: (value) {
                  setState(() {
                    _showDisabledOnly = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenCard(ScreenConfiguration config, Key key) {
    final isEnabled = config.isEnabled;
    final isVisible = config.isVisible;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 8),
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        title: Text(
          config.screenName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isEnabled ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.screenDescription ?? 'No description'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    config.category ?? 'Uncategorized',
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (!isVisible)
                  const Chip(
                    label: Text(
                      'Hidden',
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (config.requiresVerification)
                  const Chip(
                    label: Text(
                      'Needs Verification',
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visibility toggle
            IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: isVisible ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _toggleVisibility(config),
              tooltip: isVisible ? 'Hide Screen' : 'Show Screen',
            ),
            // Enable/Disable toggle
            IconButton(
              icon: Icon(
                isEnabled ? Icons.toggle_on : Icons.toggle_off,
                color: isEnabled ? Colors.green : Colors.red,
                size: 32,
              ),
              onPressed: () => _toggleEnabled(config),
              tooltip: isEnabled ? 'Disable Screen' : 'Enable Screen',
            ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditDialog(config: config),
              tooltip: 'Edit Screen',
            ),
            // Delete button (for custom screens)
            if (config.id != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteConfiguration(config),
                tooltip: 'Delete Screen',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEnabled(ScreenConfiguration config) async {
    final provider = context.read<ScreenConfigurationProvider>();
    await provider.toggleScreenEnabled(_selectedRole, config.screenId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${config.screenName} ${config.isEnabled ? 'disabled' : 'enabled'}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleVisibility(ScreenConfiguration config) async {
    final provider = context.read<ScreenConfigurationProvider>();
    await provider.toggleScreenVisibility(_selectedRole, config.screenId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${config.screenName} is now ${config.isVisible ? 'hidden' : 'visible'}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteConfiguration(ScreenConfiguration config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Screen Configuration?'),
        content: Text(
          'Are you sure you want to delete "${config.screenName}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<ScreenConfigurationProvider>();
      await provider.deleteConfiguration(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${config.screenName} deleted')),
        );
      }
    }
  }

  void _showAddEditDialog({ScreenConfiguration? config}) {
    final isEditing = config != null;
    final provider = context.read<ScreenConfigurationProvider>();

    // Form controllers
    final screenIdController = TextEditingController(text: config?.screenId ?? '');
    final screenNameController = TextEditingController(text: config?.screenName ?? '');
    final descriptionController = TextEditingController(text: config?.screenDescription ?? '');
    final sortOrderController = TextEditingController(
      text: (config?.sortOrder ?? 0).toString(),
    );

    // Design controllers
    final backgroundColorController = TextEditingController(text: config?.backgroundColor ?? '');
    final textColorController = TextEditingController(text: config?.textColor ?? '');
    final accentColorController = TextEditingController(text: config?.accentColor ?? '');
    final fontSizeController = TextEditingController(text: config?.fontSize?.toString() ?? '');
    final borderRadiusController = TextEditingController(text: config?.borderRadius?.toString() ?? '');
    final paddingController = TextEditingController(text: config?.padding?.toString() ?? '');
    final fontFamilyController = TextEditingController(text: config?.fontFamily ?? '');
    final headerBgColorController = TextEditingController(text: config?.headerBackgroundColor ?? '');
    final bottomNavColorController = TextEditingController(text: config?.bottomNavColor ?? '');
    final iconSizeController = TextEditingController(text: config?.iconSize?.toString() ?? '');

    String selectedRole = config?.role ?? _selectedRole;
    String? selectedCategory = config?.category;
    String? selectedIcon = config?.iconName;
    bool isEnabled = config?.isEnabled ?? true;
    bool isVisible = config?.isVisible ?? true;
    bool requiresVerification = config?.requiresVerification ?? false;
    bool useCardStyle = config?.useCardStyle ?? true;
    bool useShadow = config?.useShadow ?? true;
    int selectedTab = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Screen' : 'Add Custom Screen'),
            content: SizedBox(
              width: 600,
              height: 550,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      onTap: (index) => setDialogState(() => selectedTab = index),
                      tabs: const [
                        Tab(text: 'Basic', icon: Icon(Icons.settings)),
                        Tab(text: 'Design', icon: Icon(Icons.palette)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Basic Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Role selection (only when adding new)
                                if (!isEditing)
                                  DropdownButtonFormField<String>(
                                    value: selectedRole,
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: provider.availableRoles.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(role.capitalize()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedRole = value!;
                                      });
                                    },
                                  ),
                                if (!isEditing) const SizedBox(height: 16),
                                // Screen ID
                                TextField(
                                  controller: screenIdController,
                                  decoration: const InputDecoration(
                                    labelText: 'Screen ID (unique identifier)',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., custom_reports',
                                  ),
                                  enabled: !isEditing,
                                ),
                                const SizedBox(height: 16),
                                // Screen Name
                                TextField(
                                  controller: screenNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Screen Name',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., Custom Reports',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Description
                                TextField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                    hintText: 'Brief description of the screen',
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                // Category
                                DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Select Category'),
                                    ),
                                    ...provider.availableCategories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedCategory = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Icon selection
                                DropdownButtonFormField<String>(
                                  value: selectedIcon,
                                  decoration: const InputDecoration(
                                    labelText: 'Icon',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Select Icon'),
                                    ),
                                    ...provider.availableIcons.entries.map((entry) {
                                      return DropdownMenuItem(
                                        value: entry.key,
                                        child: Row(
                                          children: [
                                            Icon(_getIconData(entry.key)),
                                            const SizedBox(width: 8),
                                            Text(entry.key),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedIcon = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Sort Order
                                TextField(
                                  controller: sortOrderController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort Order',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                // Toggles
                                SwitchListTile(
                                  title: const Text('Enabled'),
                                  subtitle: const Text('Screen is accessible'),
                                  value: isEnabled,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      isEnabled = value;
                                    });
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('Visible'),
                                  subtitle: const Text('Screen appears in navigation'),
                                  value: isVisible,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      isVisible = value;
                                    });
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('Requires Verification'),
                                  subtitle: const Text('Only for verified users'),
                                  value: requiresVerification,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      requiresVerification = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Design Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customize the visual appearance of this screen',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                // Colors Section
                                Text(
                                  'Colors',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildColorPicker(
                                  'Background Color',
                                  backgroundColorController,
                                  Icons.palette,
                                  setDialogState,
                                ),
                                const SizedBox(height: 8),
                                _buildColorPicker(
                                  'Text Color',
                                  textColorController,
                                  Icons.format_color_text,
                                  setDialogState,
                                ),
                                const SizedBox(height: 8),
                                _buildColorPicker(
                                  'Accent Color',
                                  accentColorController,
                                  Icons.color_lens,
                                  setDialogState,
                                ),
                                const SizedBox(height: 8),
                                _buildColorPicker(
                                  'Header Background',
                                  headerBgColorController,
                                  Icons.app_settings_alt,
                                  setDialogState,
                                ),
                                const SizedBox(height: 8),
                                _buildColorPicker(
                                  'Bottom Nav Color',
                                  bottomNavColorController,
                                  Icons.menu,
                                  setDialogState,
                                ),
                                const SizedBox(height: 24),
                                // Typography Section
                                Text(
                                  'Typography',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: fontFamilyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Font Family',
                                    hintText: 'e.g., Roboto, Arial',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: fontSizeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Font Size (px)',
                                    hintText: 'e.g., 16',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: iconSizeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Icon Size (px)',
                                    hintText: 'e.g., 24',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 24),
                                // Layout Section
                                Text(
                                  'Layout',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: borderRadiusController,
                                  decoration: const InputDecoration(
                                    labelText: 'Border Radius (px)',
                                    hintText: 'e.g., 8',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: paddingController,
                                  decoration: const InputDecoration(
                                    labelText: 'Padding (px)',
                                    hintText: 'e.g., 16',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 24),
                                // Style Switches
                                SwitchListTile(
                                  title: const Text('Use Card Style'),
                                  subtitle: const Text('Display content in a card container'),
                                  value: useCardStyle,
                                  onChanged: (value) => setDialogState(() => useCardStyle = value),
                                ),
                                SwitchListTile(
                                  title: const Text('Use Shadow'),
                                  subtitle: const Text('Add shadow effect to the container'),
                                  value: useShadow,
                                  onChanged: (value) => setDialogState(() => useShadow = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newConfig = ScreenConfiguration(
                    id: config?.id,
                    role: selectedRole,
                    screenId: screenIdController.text.trim(),
                    screenName: screenNameController.text.trim(),
                    screenDescription: descriptionController.text.trim(),
                    isEnabled: isEnabled,
                    isVisible: isVisible,
                    sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                    iconName: selectedIcon,
                    category: selectedCategory,
                    requiresVerification: requiresVerification,
                    // Design fields
                    backgroundColor: backgroundColorController.text.trim().isEmpty
                        ? null
                        : backgroundColorController.text.trim(),
                    textColor: textColorController.text.trim().isEmpty
                        ? null
                        : textColorController.text.trim(),
                    accentColor: accentColorController.text.trim().isEmpty
                        ? null
                        : accentColorController.text.trim(),
                    fontSize: double.tryParse(fontSizeController.text),
                    borderRadius: double.tryParse(borderRadiusController.text),
                    padding: double.tryParse(paddingController.text),
                    useCardStyle: useCardStyle,
                    useShadow: useShadow,
                    fontFamily: fontFamilyController.text.trim().isEmpty
                        ? null
                        : fontFamilyController.text.trim(),
                    headerBackgroundColor: headerBgColorController.text.trim().isEmpty
                        ? null
                        : headerBgColorController.text.trim(),
                    bottomNavColor: bottomNavColorController.text.trim().isEmpty
                        ? null
                        : bottomNavColorController.text.trim(),
                    iconSize: double.tryParse(iconSizeController.text),
                  );

                  final success = isEditing
                      ? await provider.updateConfiguration(newConfig)
                      : await provider.createConfiguration(newConfig);

                  if (mounted && success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Screen updated successfully'
                              : 'Screen created successfully',
                        ),
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorPicker(String label, TextEditingController controller, IconData icon, StateSetter setDialogState) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '#FFFFFF or white',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: controller.text.isNotEmpty
            ? Container(
                margin: const EdgeInsets.all(8),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _parseColor(controller.text),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey),
                ),
              )
            : null,
      ),
      onChanged: (_) => setDialogState(() {}),
    );
  }

  Color _parseColor(String colorString) {
    if (colorString.isEmpty) return Colors.transparent;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      switch (colorString.toLowerCase()) {
        case 'white': return Colors.white;
        case 'black': return Colors.black;
        case 'red': return Colors.red;
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'yellow': return Colors.yellow;
        case 'orange': return Colors.orange;
        case 'purple': return Colors.purple;
        case 'pink': return Colors.pink;
        case 'grey': case 'gray': return Colors.grey;
        default: return Colors.transparent;
      }
    } catch (e) {
      return Colors.transparent;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'people':
        return Icons.people;
      case 'medical_services':
        return Icons.medical_services;
      case 'analytics':
        return Icons.analytics;
      case 'verified':
        return Icons.verified;
      case 'backup':
        return Icons.backup;
      case 'directions_car':
        return Icons.directions_car;
      case 'location_on':
        return Icons.location_on;
      case 'settings':
        return Icons.settings;
      case 'history':
        return Icons.history;
      case 'description':
        return Icons.description;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'person':
        return Icons.person;
      case 'pets':
        return Icons.pets;
      case 'payment':
        return Icons.payment;
      case 'map':
        return Icons.map;
      case 'emergency':
        return Icons.emergency;
      case 'inventory':
        return Icons.inventory;
      case 'folder':
        return Icons.folder;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.screen_share;
    }
  }
}

// Extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

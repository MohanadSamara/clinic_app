// lib/screens/doctor/inventory_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventoryItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Items', icon: Icon(Icons.inventory)),
            Tab(text: 'Low Stock', icon: Icon(Icons.warning)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryList(),
          _buildLowStockList(),
          _buildCategoriesView(),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        if (inventoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (inventoryProvider.inventoryItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No inventory items',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showAddItemDialog(context),
                  child: const Text('Add First Item'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inventoryProvider.inventoryItems.length,
          itemBuilder: (context, index) {
            final item = inventoryProvider.inventoryItems[index];
            return _InventoryItemCard(
              item: item,
              onEdit: () => _showEditItemDialog(context, item),
              onDelete: () => _showDeleteConfirmation(context, item),
              onUpdateStock: () => _showUpdateStockDialog(context, item),
            );
          },
        );
      },
    );
  }

  Widget _buildLowStockList() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final lowStockItems = inventoryProvider.lowStockItems;

        if (lowStockItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'All items are well stocked!',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lowStockItems.length,
          itemBuilder: (context, index) {
            final item = lowStockItems[index];
            return _InventoryItemCard(
              item: item,
              onEdit: () => _showEditItemDialog(context, item),
              onDelete: () => _showDeleteConfirmation(context, item),
              onUpdateStock: () => _showUpdateStockDialog(context, item),
              isLowStock: true,
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesView() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final categories = inventoryProvider.inventoryItems
            .map((item) => item.category)
            .toSet()
            .toList();

        if (categories.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryItems = inventoryProvider.getItemsByCategory(
              category,
            );
            final totalValue = categoryItems.fold<double>(
              0,
              (sum, item) => sum + (item.quantity * item.cost),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${categoryItems.length} items • Total value: \$${totalValue.toStringAsFixed(2)}',
                ),
                children: categoryItems.map((item) {
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('Quantity: ${item.quantity} ${item.unit}'),
                    trailing: Text(
                      '\$${(item.quantity * item.cost).toStringAsFixed(2)}',
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEditInventoryItemDialog(),
    );
  }

  void _showEditItemDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => _AddEditInventoryItemDialog(item: item),
    );
  }

  void _showUpdateStockDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => _UpdateStockDialog(item: item),
    );
  }

  void _showDeleteConfirmation(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (item.id != null) {
                await context.read<InventoryProvider>().deleteInventoryItem(
                  item.id!,
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('${item.name} deleted')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateStock;
  final bool isLowStock;

  const _InventoryItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStock,
    this.isLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isLowStock ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        item.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${item.category}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'stock':
                        onUpdateStock();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'stock',
                      child: Text('Update Stock'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock: ${item.quantity} ${item.unit}',
                        style: TextStyle(
                          color: item.isLowStock ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Min Threshold: ${item.minThreshold} ${item.unit}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.cost.toStringAsFixed(2)} per ${item.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: \$${(item.quantity * item.cost).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditInventoryItemDialog extends StatefulWidget {
  final InventoryItem? item;

  const _AddEditInventoryItemDialog({this.item});

  @override
  State<_AddEditInventoryItemDialog> createState() =>
      _AddEditInventoryItemDialogState();
}

class _AddEditInventoryItemDialogState
    extends State<_AddEditInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minThresholdController = TextEditingController();
  final _unitController = TextEditingController();
  final _costController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description;
      _quantityController.text = widget.item!.quantity.toString();
      _minThresholdController.text = widget.item!.minThreshold.toString();
      _unitController.text = widget.item!.unit;
      _costController.text = widget.item!.cost.toString();
      _categoryController.text = widget.item!.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Add Inventory Item' : 'Edit Inventory Item',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter item name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter description' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final qty = int.tryParse(value!);
                        if (qty == null || qty < 0) return 'Invalid quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter unit' : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _minThresholdController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Threshold',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  final threshold = int.tryParse(value!);
                  if (threshold == null || threshold < 0)
                    return 'Invalid threshold';
                  return null;
                },
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost per Unit'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  final cost = double.tryParse(value!);
                  if (cost == null || cost < 0) return 'Invalid cost';
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter category' : null,
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
              final item = InventoryItem(
                id: widget.item?.id,
                name: _nameController.text,
                description: _descriptionController.text,
                quantity: int.parse(_quantityController.text),
                minThreshold: int.parse(_minThresholdController.text),
                unit: _unitController.text,
                cost: double.parse(_costController.text),
                category: _categoryController.text,
              );

              final success = widget.item == null
                  ? await context.read<InventoryProvider>().addInventoryItem(
                      item,
                    )
                  : await context.read<InventoryProvider>().updateInventoryItem(
                      item,
                    );

              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.item == null
                          ? 'Item added successfully'
                          : 'Item updated successfully',
                    ),
                  ),
                );
              }
            }
          },
          child: Text(widget.item == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _minThresholdController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}

class _UpdateStockDialog extends StatefulWidget {
  final InventoryItem item;

  const _UpdateStockDialog({required this.item});

  @override
  State<_UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends State<_UpdateStockDialog> {
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.item.quantity.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stock: ${widget.item.name}'),
      content: TextFormField(
        controller: _quantityController,
        decoration: InputDecoration(
          labelText: 'New Quantity (${widget.item.unit})',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          final qty = int.tryParse(value!);
          if (qty == null || qty < 0) return 'Invalid quantity';
          return null;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newQuantity = int.tryParse(_quantityController.text);
            if (newQuantity != null &&
                newQuantity >= 0 &&
                widget.item.id != null) {
              final success = await context
                  .read<InventoryProvider>()
                  .updateStockQuantity(widget.item.id!, newQuantity);
              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock updated successfully')),
                );
              }
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}

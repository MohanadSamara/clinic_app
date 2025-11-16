import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/service.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadServices();
    });
  }

  Future<void> _addService() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final promotionalPriceController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: promotionalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Promotional Price (optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'price': double.tryParse(priceController.text) ?? 0,
              'promotionalPrice': promotionalPriceController.text.isNotEmpty
                  ? double.tryParse(promotionalPriceController.text)
                  : null,
              'category': categoryController.text,
              'description': descriptionController.text,
            }),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final service = Service(
          name: result['name'],
          price: result['price'],
          promotionalPrice: result['promotionalPrice'],
          category: result['category'],
          description: result['description'],
        );
        await context.read<AppointmentProvider>().addService(service);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Service added')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding service: $e')));
      }
    }
  }

  Future<void> _editService(Service service) async {
    final nameController = TextEditingController(text: service.name);
    final priceController = TextEditingController(
      text: service.price.toString(),
    );
    final promotionalPriceController = TextEditingController(
      text: service.promotionalPrice?.toString() ?? '',
    );
    final categoryController = TextEditingController(text: service.category);
    final descriptionController = TextEditingController(
      text: service.description ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: promotionalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Promotional Price (optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'price': double.tryParse(priceController.text) ?? 0,
              'promotionalPrice': promotionalPriceController.text.isNotEmpty
                  ? double.tryParse(promotionalPriceController.text)
                  : null,
              'category': categoryController.text,
              'description': descriptionController.text,
            }),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedService = service.copyWith(
          name: result['name'],
          price: result['price'],
          promotionalPrice: result['promotionalPrice'],
          category: result['category'],
          description: result['description'],
        );
        await context.read<AppointmentProvider>().updateService(updatedService);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Service updated')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating service: $e')));
      }
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete ${service.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<AppointmentProvider>().deleteService(service.id!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Service deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addService),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = provider.services;
          if (services.isEmpty) {
            return const Center(child: Text('No services found'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final displayPrice = service.promotionalPrice ?? service.price;
              final originalPrice = service.promotionalPrice != null
                  ? service.price
                  : null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${service.category} - \$${displayPrice.toStringAsFixed(2)}${originalPrice != null ? ' (was \$${originalPrice.toStringAsFixed(2)})' : ''}',
                      ),
                      if (service.description != null &&
                          service.description!.isNotEmpty)
                        Text(
                          service.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editService(service);
                      } else if (value == 'delete') {
                        _deleteService(service);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

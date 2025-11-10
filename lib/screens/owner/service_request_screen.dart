import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet.dart';
import '../../models/service_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/service_request_provider.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  String _requestType = 'urgent';
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  Pet? _selectedPet;
  bool _shareLocation = true;
  bool _loadingLocation = false;
  double? _latitude;
  double? _longitude;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPets();
    });
  }

  Future<void> _loadPets() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      await context.read<PetProvider>().loadPets(ownerId: auth.user!.id!);
      if (mounted) {
        setState(() {
          final pets = context.read<PetProvider>().pets;
          if (pets.isNotEmpty) {
            _selectedPet = pets.first;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    return Scaffold(
      appBar: AppBar(title: const Text('Request Mobile Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select pet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Pet>(
              value: _selectedPet,
              items: pets
                  .map(
                    (pet) => DropdownMenuItem(
                      value: pet,
                      child: Text('${pet.name} (${pet.species})'),
                    ),
                  )
                  .toList(),
              onChanged: (pet) => setState(() => _selectedPet = pet),
            ),
            const SizedBox(height: 24),
            ToggleButtons(
              isSelected: [
                _requestType == 'urgent',
                _requestType == 'checkup',
              ],
              onPressed: (index) {
                setState(() {
                  _requestType = index == 0 ? 'urgent' : 'checkup';
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Urgent dispatch'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Schedule checkup'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Describe the issue or request',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_requestType == 'urgent')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Share my current location with dispatch'),
                    value: _shareLocation,
                    onChanged: (value) => setState(() => _shareLocation = value),
                  ),
                  if (_shareLocation)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadingLocation ? null : _captureLocation,
                          icon: _loadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: const Text('Use current location'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _latitude == null
                                ? 'Location not captured yet'
                                : 'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred visit address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month),
                    title: Text(
                      _scheduledDate == null
                          ? 'Select preferred date'
                          : DateFormat('yMMMd').format(_scheduledDate!),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _scheduledDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() => _scheduledDate = picked);
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                child: const Text('Submit request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() {
      _loadingLocation = true;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to capture location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit requests')),
      );
      return;
    }

    if (_requestType == 'urgent' && _shareLocation && _latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share your location for urgent dispatch')), 
      );
      return;
    }

    final provider = context.read<ServiceRequestProvider>();
    final request = ServiceRequest(
      ownerId: auth.user!.id!,
      petId: _selectedPet!.id!,
      requestType: _requestType,
      description: _descriptionController.text,
      status: 'pending',
      latitude: _shareLocation ? _latitude : null,
      longitude: _shareLocation ? _longitude : null,
      address: _requestType == 'checkup' ? _addressController.text : null,
      requestDate: DateTime.now(),
      scheduledDate: _requestType == 'checkup' ? _scheduledDate : null,
    );

    final success = await provider.createRequest(request);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully')),
      );
      Navigator.of(context).pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request')),
        );
      }
    }
  }
}

// lib/screens/owner/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../../db/db_helper.dart';
import '../select_location_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  Service? _selectedService;
  Pet? _selectedPet;
  List<Pet> _userPets = [];
  User? _selectedDoctor;
  List<User> _doctors = [];
  TimeOfDay? _selectedTime;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _urgencyLevel = 'routine';

  bool _shareLocation = false;
  bool _locating = false;
  double? _lat;
  double? _lng;
  String? _locError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadServices();
      _loadUserPets();
      _loadDoctors();
    });
  }

  Future<void> _loadUserPets() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id != null) {
      await context.read<PetProvider>().loadPets(
        ownerId: authProvider.user!.id!,
      );
      setState(() {
        _userPets = context.read<PetProvider>().pets;
      });
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final doctorsData = await DBHelper.instance.getAllUsers(role: 'doctor');
      setState(() {
        _doctors = doctorsData.map((data) => User.fromMap(data)).toList();
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    }
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _locError = null;
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
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      setState(() {
        _locError = e.toString();
      });
    } finally {
      setState(() {
        _locating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Consumer<AppointmentProvider>(
        builder: (context, appointmentProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 90)),
                    focusedDay: _selectedDate,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select Time',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Service>(
                  initialValue: _selectedService,
                  hint: const Text('Choose a service'),
                  items: appointmentProvider.services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text('${service.name} - \$${service.price}'),
                    );
                  }).toList(),
                  onChanged: (service) {
                    setState(() {
                      _selectedService = service;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Doctor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<User>(
                  initialValue: _selectedDoctor,
                  hint: const Text('Choose a doctor'),
                  items: _doctors.map((doctor) {
                    return DropdownMenuItem(
                      value: doctor,
                      child: Text('Dr. ${doctor.name}'),
                    );
                  }).toList(),
                  onChanged: (doctor) {
                    setState(() {
                      _selectedDoctor = doctor;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a doctor' : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Pet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Pet>(
                  initialValue: _selectedPet,
                  hint: const Text('Choose a pet'),
                  items: _userPets.map((pet) {
                    return DropdownMenuItem(
                      value: pet,
                      child: Text('${pet.name} (${pet.species})'),
                    );
                  }).toList(),
                  onChanged: (pet) {
                    setState(() {
                      _selectedPet = pet;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a pet' : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Urgency Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _urgencyLevel,
                  items: const [
                    DropdownMenuItem(value: 'routine', child: Text('Routine')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(
                      value: 'emergency',
                      child: Text('Emergency (Urgent)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _urgencyLevel = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_urgencyLevel != 'routine') ...[
                  SwitchListTile(
                    title: const Text('Share current location'),
                    value: _shareLocation,
                    onChanged: (v) {
                      setState(() {
                        _shareLocation = v;
                      });
                    },
                  ),
                  if (_shareLocation) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _locating ? null : _captureLocation,
                          icon: _locating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: const Text('Get current location'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _locError != null
                                ? 'Error: $_locError'
                                : (_lat != null && _lng != null)
                                ? 'Lat: ${_lat!.toStringAsFixed(5)}, Lng: ${_lng!.toStringAsFixed(5)}'
                                : 'Not captured yet',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: () => _openMapForAddress(),
                    ),
                  ),
                  readOnly: true, // Make it read-only since we'll use map
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _bookAppointment() async {
    if (_selectedService == null ||
        _selectedTime == null ||
        _selectedPet == null ||
        _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select service, time, pet, and doctor'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (_urgencyLevel != 'routine' &&
        _shareLocation &&
        (_lat == null || _lng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture your location')),
      );
      return;
    }

    final appointment = Appointment(
      ownerId: authProvider.user!.id!,
      petId: _selectedPet!.id!, // Use selected pet ID
      doctorId: _selectedDoctor!.id!, // Required doctor ID
      serviceType: _selectedService!.name,
      description: _descriptionController.text,
      scheduledAt: scheduledDateTime.toIso8601String(),
      address: _addressController.text,
      price: _selectedService!.price,
      urgencyLevel: _urgencyLevel,
      locationLat: _shareLocation ? _lat : null,
      locationLng: _shareLocation ? _lng : null,
    );

    final success = await context.read<AppointmentProvider>().bookAppointment(
      appointment,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book appointment')),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _openMapForAddress() async {
    // Navigate to the new SelectLocationScreen
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const SelectLocationScreen()),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result['address'] ?? '';
        _lat = result['lat'];
        _lng = result['lng'];
      });
    }
  }
}

class _MapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const _MapPickerDialog({
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  double _selectedLat = 31.963158; // Amman, Jordan
  double _selectedLng = 35.930359;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLat = widget.initialLat!;
      _selectedLng = widget.initialLng!;
    }
    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if Google Maps is supported on this platform
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop platforms, show a simplified location picker
      return _buildDesktopLocationPicker();
    } else {
      // For mobile platforms, show a message about map integration
      return _buildMobileLocationPicker();
    }
  }

  Widget _buildDesktopLocationPicker() {
    return Dialog(
      child: SizedBox(
        height: 400,
        width: 400,
        child: Column(
          children: [
            AppBar(
              title: const Text('Select Location (Desktop)'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop({
                    'address': _selectedAddress,
                    'lat': _selectedLat,
                    'lng': _selectedLng,
                  }),
                  child: const Text('Save'),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Location Coordinates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: 'e.g., 31.963158',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: _selectedLat.toString(),
                      ),
                      onChanged: (value) {
                        final lat = double.tryParse(value);
                        if (lat != null && lat >= -90 && lat <= 90) {
                          setState(() {
                            _selectedLat = lat;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: 'e.g., 35.930359',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: _selectedLng.toString(),
                      ),
                      onChanged: (value) {
                        final lng = double.tryParse(value);
                        if (lng != null && lng >= -180 && lng <= 180) {
                          setState(() {
                            _selectedLng = lng;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
                        hintText: 'Enter address or leave blank',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _selectedAddress),
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Selection:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Lat: ${_selectedLat.toStringAsFixed(6)}'),
                          Text('Lng: ${_selectedLng.toStringAsFixed(6)}'),
                          if (_selectedAddress.isNotEmpty)
                            Text('Address: $_selectedAddress'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLocationPicker() {
    return Dialog(
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            AppBar(
              title: const Text('Location Selection'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Interactive Map',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Map integration will be available on mobile devices.\n\nFor now, please enter your location manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop({
                        'address': 'Location selected',
                        'lat': 31.963158,
                        'lng': 35.930359,
                      }),
                      icon: const Icon(Icons.check),
                      label: const Text('Use Default Location'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

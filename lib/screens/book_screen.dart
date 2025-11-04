// lib/screens/book_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../db/db_helper.dart';
import '../models/pet.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  List<Pet> pets = [];
  Pet? selectedPet;
  final _address = TextEditingController();
  DateTime? _selectedDate;
  bool loading = true;
  final _serviceCtl = TextEditingController();
  final _priceCtl = TextEditingController(text: '20.0');

  final List<String> services = [
    'Vaccination',
    'Checkup',
    'Dental Care',
    'Emergency',
    'Surgery',
    'Grooming',
  ];
  String? selectedService;

  Future<void> loadPets() async {
    final ownerId = Provider.of<AuthProvider>(context, listen: false).user!.id!;
    final rows = await DBHelper.instance.getPetsByOwner(ownerId);
    setState(() {
      pets = rows.map((r) => Pet.fromMap(r)).toList();
      if (pets.isNotEmpty) selectedPet = pets.first;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Choose Service Section
                  Text(
                    'Choose Service',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Selection Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3,
                        ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _ServiceOption(
                        service: service,
                        isSelected: selectedService == service,
                        onTap: () {
                          setState(() {
                            selectedService = service;
                            _serviceCtl.text = service;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Pet Selection
                  Text(
                    'Select Pet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Pet>(
                      isExpanded: true,
                      value: selectedPet,
                      underline: const SizedBox(),
                      items: pets
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        selectedPet = v;
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date & Time Selection
                  Text(
                    'Choose Date & Time',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null
                                    ? 'No date chosen'
                                    : DateFormat.yMMMMd().format(
                                        _selectedDate!,
                                      ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null
                                    ? 'No time chosen'
                                    : DateFormat.jm().format(_selectedDate!),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _pickDateTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Pick Date & Time'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Details
                  TextField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _priceCtl,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 32),

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedPet == null ||
        _selectedDate == null ||
        selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select service, pet, and date/time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ownerId = Provider.of<AuthProvider>(context, listen: false).user!.id!;
    final payload = {
      'owner_id': ownerId,
      'pet_id': selectedPet!.id,
      'service_type': selectedService!,
      'scheduled_at': _selectedDate!.toIso8601String(),
      'address': _address.text,
      'price': double.tryParse(_priceCtl.text) ?? 0.0,
      'status': 'pending',
    };

    await DBHelper.instance.insertAppointment(payload);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment booked successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }
}

class _ServiceOption extends StatelessWidget {
  final String service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceOption({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            service,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}

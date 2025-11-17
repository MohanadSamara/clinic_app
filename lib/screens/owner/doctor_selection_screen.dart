// lib/screens/owner/doctor_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';
import '../../models/service.dart';
import '../../components/modern_cards.dart';
import 'booking_screen.dart';

class DoctorSelectionScreen extends StatefulWidget {
  final Service? selectedService;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  const DoctorSelectionScreen({
    super.key,
    this.selectedService,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  List<User> _doctors = [];
  List<User> _filteredDoctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSpecialty = 'All';
  double _minRating = 0.0;
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final dbHelper = DBHelper.instance;
      final allUsers = await dbHelper.getAllUsers(role: 'doctor');
      final doctors = <User>[];

      for (final userData in allUsers) {
        doctors.add(User.fromMap(userData));
      }

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _filteredDoctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        // Search by name or email
        final matchesSearch =
            _searchQuery.isEmpty ||
            doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doctor.email.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filter by specialty (placeholder - would need specialty field)
        final matchesSpecialty =
            _selectedSpecialty == 'All' ||
            doctor.name.contains(_selectedSpecialty); // Placeholder logic

        // Filter by rating (placeholder - would need rating system)
        final matchesRating = true; // Placeholder

        // Filter by availability (placeholder)
        final matchesAvailability = !_availableOnly || true; // Placeholder

        return matchesSearch &&
            matchesSpecialty &&
            matchesRating &&
            matchesAvailability;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Doctor'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search doctors...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _filterDoctors();
                        },
                      ),
                      const SizedBox(height: 12),
                      // Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSpecialty,
                              decoration: InputDecoration(
                                labelText: 'Specialty',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'All',
                                  child: Text('All Specialties'),
                                ),
                                DropdownMenuItem(
                                  value: 'General',
                                  child: Text('General Practice'),
                                ),
                                DropdownMenuItem(
                                  value: 'Surgery',
                                  child: Text('Surgery'),
                                ),
                                DropdownMenuItem(
                                  value: 'Dermatology',
                                  child: Text('Dermatology'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSpecialty = value!;
                                });
                                _filterDoctors();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilterChip(
                            label: const Text('Available Only'),
                            selected: _availableOnly,
                            onSelected: (selected) {
                              setState(() {
                                _availableOnly = selected;
                              });
                              _filterDoctors();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Doctor List
                Expanded(
                  child: _filteredDoctors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No doctors found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = _filteredDoctors[index];
                            return _DoctorCard(
                              doctor: doctor,
                              onSelect: () => _selectDoctor(doctor),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _selectDoctor(User doctor) {
    // Navigate to booking screen with selected doctor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          selectedService: widget.selectedService,
          selectedDate: widget.selectedDate,
          selectedTime: widget.selectedTime,
          selectedDoctor: doctor,
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final User doctor;
  final VoidCallback onSelect;

  const _DoctorCard({required this.doctor, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Doctor Avatar
              CircleAvatar(
                radius: 35,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  doctor.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Veterinary Medicine', // Placeholder specialty
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating and Experience
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.8', // Placeholder rating
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.work, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '8 years exp.', // Placeholder experience
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Availability
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Available Today', // Placeholder availability
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[700]
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

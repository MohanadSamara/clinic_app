// lib/screens/owner/doctor_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';
import '../../models/service.dart';
import '../../components/modern_cards.dart';
import '../../theme/app_theme.dart';
import '../../components/ui_kit.dart';
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
                SectionHeader(
                  title: 'Choose a Doctor',
                  subtitle: 'Select a vet based on your pet and service',
                ),
                // Search and Filter Bar
                Container(
                  padding: EdgeInsets.all(AppTheme.padding),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search doctors...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
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
                              decoration: const InputDecoration(
                                labelText: 'Specialty',
                                contentPadding: EdgeInsets.symmetric(
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
                      ? EmptyState(
                          icon: Icons.medical_services_outlined,
                          title: 'No doctors found',
                          message: 'Try adjusting your search or filters',
                        )
                      : Card(
                          margin: EdgeInsets.all(AppTheme.padding),
                          child: ListView.builder(
                            padding: EdgeInsets.all(AppTheme.padding),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return CompactSpecialistCard(
                                name: doctor.name,
                                specialty: 'Veterinary Medicine',
                                area: doctor.area ?? 'Not specified',
                                rating: 4.8,
                                reviewCount: 42,
                                onTap: () => _selectDoctor(doctor),
                              );
                            },
                          ),
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

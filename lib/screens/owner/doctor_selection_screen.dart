// lib/screens/owner/doctor_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../models/user.dart';
import '../../models/service.dart';
import '../../models/location_data.dart';
import '../../theme/app_theme.dart';
import '../../components/ui_kit.dart';
import '../../providers/locale_provider.dart';
import '../../../translations.dart';
import 'booking_screen.dart';
import 'dart:math';

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
  String? _selectedDistrict;

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

      // Get owner's selected district
      District? ownerDistrict;
      if (_selectedDistrict != null) {
        ownerDistrict = AmmanDistricts.getDistrictByName(_selectedDistrict!);
      }

      // Filter doctors to only those in the same district as the owner
      final filteredDoctors = doctors.where((doctor) {
        if (ownerDistrict == null)
          return true; // If owner has no district, show all doctors
        if (doctor.area == null) return false;
        final doctorDistrict =
            AmmanDistricts.getDistrictBySubArea(doctor.area!) ??
            AmmanDistricts.getDistrictByName(doctor.area!);
        return doctorDistrict != null &&
            doctorDistrict.name == ownerDistrict.name;
      }).toList();

      // Sort filtered doctors by proximity within the district
      if (ownerDistrict != null) {
        filteredDoctors.sort((a, b) {
          final aDistrict = a.area != null
              ? AmmanDistricts.getDistrictBySubArea(a.area!)
              : null;
          final bDistrict = b.area != null
              ? AmmanDistricts.getDistrictBySubArea(b.area!)
              : null;

          // Sort by distance within the same district
          final aDistance =
              (aDistrict != null &&
                  aDistrict.centerLat != null &&
                  aDistrict.centerLng != null)
              ? _calculateDistance(
                  ownerDistrict!.centerLat,
                  ownerDistrict!.centerLng,
                  aDistrict.centerLat!,
                  aDistrict.centerLng!,
                )
              : double.infinity;
          final bDistance =
              (bDistrict != null &&
                  bDistrict.centerLat != null &&
                  bDistrict.centerLng != null)
              ? _calculateDistance(
                  ownerDistrict!.centerLat,
                  ownerDistrict!.centerLng,
                  bDistrict.centerLat!,
                  bDistrict.centerLng!,
                )
              : double.infinity;

          return aDistance.compareTo(bDistance);
        });
      }

      if (mounted) {
        setState(() {
          _doctors = filteredDoctors;
          _filteredDoctors = filteredDoctors;
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
        title: Text(context.tr('selectDoctor')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SectionHeader(
                  title: context.tr('chooseDoctor'),
                  subtitle: context.tr('selectDoctor'),
                ),
                // Search and Filter Bar
                Container(
                  padding: EdgeInsets.all(AppTheme.padding),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // District Selection
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          labelText: context.tr('selectDistrict'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(context.tr('selectDistrict')),
                          ),
                          ...AmmanDistricts.allDistricts.map((district) {
                            return DropdownMenuItem<String>(
                              value: district.name,
                              child: Text(district.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                          _loadDoctors();
                        },
                      ),
                      const SizedBox(height: 12),
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: context.tr('searchDoctors'),
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
                              decoration: InputDecoration(
                                labelText: context.tr('specialty'),
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
                              final doctorDistrict = doctor.area != null
                                  ? AmmanDistricts.getDistrictBySubArea(
                                          doctor.area!,
                                        ) ??
                                        AmmanDistricts.getDistrictByName(
                                          doctor.area!,
                                        )
                                  : null;
                              return CompactSpecialistCard(
                                name: doctor.name,
                                specialty: 'Veterinary Medicine',
                                area:
                                    doctorDistrict?.name ??
                                    doctor.area ??
                                    'Not specified',
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

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLng = (lng2 - lng1) * (pi / 180);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
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

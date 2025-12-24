// lib/screens/owner/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/availability_provider.dart';
import '../../db/db_helper.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../select_location_screen.dart';
import '../../../translations.dart';
import 'package:clinic_app/translations/translations.dart';
import 'package:get/get.dart' hide Translations;

class BookingScreen extends StatefulWidget {
  final Service? selectedService;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final User? selectedDoctor;

  const BookingScreen({
    super.key,
    this.selectedService,
    this.selectedDate,
    this.selectedTime,
    this.selectedDoctor,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _selectedDate;
  Service? _selectedService;
  Pet? _selectedPet;
  List<Pet> _userPets = [];
  User? _selectedDoctor;
  int? _selectedDoctorId;
  List<User> _doctors = [];
  TimeOfDay? _selectedTime;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _urgencyLevel = 'routine';
  String _paymentMethod = 'online'; // Default to online payment

  bool _shareLocation = false;
  bool _locating = false;
  double? _lat;
  double? _lng;
  String? _locError;

  @override
  void initState() {
    super.initState();
    // Initialize with passed parameters
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _selectedService = widget.selectedService;
    _selectedTime = widget.selectedTime;
    _selectedDoctorId = widget.selectedDoctor?.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadServices();
      _loadUserPets();
      _loadDoctors();
      context.read<AvailabilityProvider>().loadAvailabilityData();
    });
  }

  Future<void> _loadUserPets() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id != null) {
      await context.read<PetProvider>().loadPets(
        ownerId: authProvider.user!.id!,
      );
      setState(() {
        _userPets = context
            .read<PetProvider>()
            .pets
            .take(20)
            .toList(); // Limit pets for performance
      });
    }
  }

  Future<void> _loadDoctors() async {
    try {
      // Get all doctors from the database
      final dbHelper = DBHelper.instance;
      final allUsers = await dbHelper.getAllUsers(role: 'doctor');
      final doctors = <User>[];

      for (final userData in allUsers) {
        doctors.add(User.fromMap(userData));
      }

      setState(() {
        _doctors = doctors;
        // Set selected doctor based on ID if provided
        if (_selectedDoctorId != null) {
          _selectedDoctor = _doctors.firstWhere(
            (doctor) => doctor.id == _selectedDoctorId,
            orElse: () => User(id: null, name: '', email: '', password: ''),
          );
          // If not found, clear the selection
          if (_selectedDoctor?.id == null) {
            _selectedDoctor = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      setState(() {
        _doctors = [];
      });
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
      appBar: AppBar(
        title: Text(context.tr('bookAppointment')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, appointmentProvider, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, animationValue, child) {
              return Opacity(
                opacity: animationValue,
                child: Translations.get(
                  offset: Offset(0, 20 * (1 - animationValue)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, headerValue, child) {
                            return Opacity(
                              opacity: headerValue,
                              child: Translations.get(
                                offset: Offset(-30 * (1 - headerValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('scheduleVisit'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('bookVetCare'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Date Selection Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, dateValue, child) {
                            return Opacity(
                              opacity: dateValue,
                              child: Translations.get(
                                offset: Offset(30 * (1 - dateValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('selectDate'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: SizedBox(
                                        height:
                                            400, // Constrain the calendar height to prevent overflow
                                        child: TableCalendar(
                                          firstDay: DateTime.now(),
                                          lastDay: DateTime.now().add(
                                            const Duration(days: 90),
                                          ),
                                          focusedDay: _selectedDate,
                                          selectedDayPredicate: (day) =>
                                              isSameDay(_selectedDate, day),
                                          onDaySelected:
                                              (selectedDay, focusedDay) {
                                                setState(() {
                                                  _selectedDate = selectedDay;
                                                });
                                              },
                                          calendarStyle: CalendarStyle(
                                            selectedDecoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            todayDecoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            defaultTextStyle: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                            weekendTextStyle: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                          ),
                                          headerStyle: HeaderStyle(
                                            titleTextStyle: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                            formatButtonTextStyle: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Time Selection Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, timeValue, child) {
                            return Opacity(
                              opacity: timeValue,
                              child: Translations.get(
                                offset: Offset(-30 * (1 - timeValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('selectTime'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                                  ? _selectedTime!.format(
                                                      context,
                                                    )
                                                  : context.tr('selectTime'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Service Selection Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, serviceValue, child) {
                            return Opacity(
                              opacity: serviceValue,
                              child: Translations.get(
                                offset: Offset(30 * (1 - serviceValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('selectService'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<Service>(
                                      value: _selectedService,
                                      hint: Text(context.tr('chooseService')),
                                      items: appointmentProvider.services.map((
                                        service,
                                      ) {
                                        return DropdownMenuItem(
                                          value: service,
                                          child: Text(
                                            '${service.name} - \$${service.price}',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (service) {
                                        setState(() {
                                          _selectedService = service;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Clinic Availability Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, availabilityValue, child) {
                            return Opacity(
                              opacity: availabilityValue,
                              child: Translations.get(
                                offset: Offset(
                                  -30 * (1 - availabilityValue),
                                  0,
                                ),
                                child: Consumer<AvailabilityProvider>(
                                  builder: (context, availabilityProvider, child) {
                                    final availablePairs =
                                        availabilityProvider.availablePairs;
                                    if (availablePairs.isEmpty) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .errorContainer
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warning,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                context.tr(
                                                  'noDoctorsAvailableAtTheMomentPleaseCheckBackLater',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.medical_services,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                context.tr('availableTeams'),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '${availablePairs.length} ${context.tr('doctorsAvailableForHomeVisits')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: availablePairs.map((
                                              pair,
                                            ) {
                                              final doctor = pair['doctor']!;
                                              final driver = pair['driver']!;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      context.tr(
                                                        'doctorNamePrefix',
                                                        args: {
                                                          'name': doctor.name,
                                                        },
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.directions_car,
                                                      size: 16,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.secondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      driver.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Doctor Selection Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, doctorValue, child) {
                            return Opacity(
                              opacity: doctorValue,
                              child: Translations.get(
                                offset: Offset(-30 * (1 - doctorValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('selectDoctor'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_selectedDoctor != null)
                                      // Show selected doctor as read-only
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              (Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? const Color(0xFF34D399)
                                                      : Colors.green)
                                                  .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF34D399)
                                                : Colors.green,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF34D399)
                                                  : Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${context.tr('dr')} ${_selectedDoctor!.name}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF34D399)
                                                    : Colors.green,
                                              ),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedDoctor = null;
                                                  _selectedDoctorId = null;
                                                });
                                              },
                                              child: Text(context.tr('change')),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_doctors.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              (Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? const Color(0xFFFFB74D)
                                                      : Colors.orange)
                                                  .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFFFFB74D)
                                                : Colors.orange,
                                          ),
                                        ),
                                        child: Text(
                                          context.tr('noDoctorsAvailable'),
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFFFFB74D)
                                                : Colors.orange,
                                          ),
                                        ),
                                      )
                                    else
                                      DropdownButtonFormField<User>(
                                        hint: Text(context.tr('chooseDoctor')),
                                        items: _doctors.map((doctor) {
                                          return DropdownMenuItem(
                                            value: doctor,
                                            child: Text(
                                              context.tr(
                                                'doctorNamePrefix',
                                                args: {'name': doctor.name},
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (doctor) {
                                          setState(() {
                                            _selectedDoctor = doctor;
                                          });
                                        },
                                        validator: (value) => value == null
                                            ? context.tr('chooseDoctor')
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Pet Selection Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1100),
                          builder: (context, petValue, child) {
                            return Opacity(
                              opacity: petValue,
                              child: Translations.get(
                                offset: Offset(30 * (1 - petValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('selectPet'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<Pet>(
                                      initialValue: _selectedPet,
                                      hint: Text(context.tr('choosePet')),
                                      items: _userPets.map((pet) {
                                        return DropdownMenuItem(
                                          value: pet,
                                          child: Text(
                                            '${pet.name} (${pet.species})',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (pet) {
                                        setState(() {
                                          _selectedPet = pet;
                                        });
                                      },
                                      validator: (value) => value == null
                                          ? context.tr('choosePet')
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Urgency and Location Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          builder: (context, urgencyValue, child) {
                            return Opacity(
                              opacity: urgencyValue,
                              child: Translations.get(
                                offset: Offset(-30 * (1 - urgencyValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('urgencyLevel'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _urgencyLevel,
                                      items: [
                                        DropdownMenuItem(
                                          value: 'routine',
                                          child: Text(context.tr('routine')),
                                        ),
                                        DropdownMenuItem(
                                          value: 'urgent',
                                          child: Text(context.tr('urgent')),
                                        ),
                                        DropdownMenuItem(
                                          value: 'emergency',
                                          child: Text(context.tr('emergency')),
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
                                        title: Text(
                                          context.tr('shareCurrentLocation'),
                                        ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _locating
                                                  ? null
                                                  : _captureLocation,
                                              icon: _locating
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.my_location,
                                                    ),
                                              label: Text(
                                                context.tr(
                                                  'getCurrentLocation',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _locError != null
                                                    ? context.tr(
                                                        'locationError',
                                                        args: {
                                                          'error': _locError!,
                                                        },
                                                      )
                                                    : (_lat != null &&
                                                          _lng != null)
                                                    ? context.tr(
                                                        'coordinatesFormat',
                                                        args: {
                                                          'lat': _lat!
                                                              .toStringAsFixed(
                                                                5,
                                                              ),
                                                          'lng': _lng!
                                                              .toStringAsFixed(
                                                                5,
                                                              ),
                                                        },
                                                      )
                                                    : context.tr(
                                                        'locationNotCaptured',
                                                      ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Location Selection Section (Always Required)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1300),
                          builder: (context, locationValue, child) {
                            return Opacity(
                              opacity: locationValue,
                              child: Translations.get(
                                offset: Offset(-30 * (1 - locationValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('appointmentLocation'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('locationDescription'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _addressController.text.isEmpty
                                              ? (Theme.of(context).brightness ==
                                                            Brightness.dark
                                                        ? const Color(
                                                            0xFFF87171,
                                                          )
                                                        : Colors.red)
                                                    .withOpacity(0.5)
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withOpacity(0.3),
                                          width: _addressController.text.isEmpty
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _addressController,
                                        decoration: InputDecoration(
                                          labelText:
                                              _addressController.text.isEmpty
                                              ? context.tr('clickMapIcon')
                                              : context.tr('selectedLocation'),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.map,
                                              color:
                                                  _addressController
                                                      .text
                                                      .isEmpty
                                                  ? (Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? const Color(
                                                            0xFFF87171,
                                                          )
                                                        : Colors.red)
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                            ),
                                            onPressed: () =>
                                                _openMapForAddress(),
                                          ),
                                        ),
                                        readOnly: true,
                                        maxLines: 2,
                                      ),
                                    ),
                                    if (_addressController.text.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          context.tr('locationRequired'),
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFFF87171)
                                                : Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Payment Method Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1300),
                          builder: (context, paymentValue, child) {
                            return Opacity(
                              opacity: paymentValue,
                              child: Translations.get(
                                offset: Offset(30 * (1 - paymentValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('paymentMethod'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr(
                                        'chooseHowYouWouldLikeToPayForThisAppointment',
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          RadioListTile<String>(
                                            title: Text(
                                              context.tr('payOnline'),
                                            ),
                                            subtitle: Text(
                                              context.tr(
                                                'securePaymentWithCard',
                                              ),
                                            ),
                                            value: 'online',
                                            groupValue: _paymentMethod,
                                            onChanged: (value) {
                                              setState(() {
                                                _paymentMethod = value!;
                                              });
                                            },
                                            activeColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const Divider(),
                                          RadioListTile<String>(
                                            title: Text(
                                              context.tr('payOnArrival'),
                                            ),
                                            subtitle: Text(
                                              context.tr(
                                                'payCashWhenServiceIsProvided',
                                              ),
                                            ),
                                            value: 'cash',
                                            groupValue: _paymentMethod,
                                            onChanged: (value) {
                                              setState(() {
                                                _paymentMethod = value!;
                                              });
                                            },
                                            activeColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Description Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1400),
                          builder: (context, detailsValue, child) {
                            return Opacity(
                              opacity: detailsValue,
                              child: Translations.get(
                                offset: Offset(30 * (1 - detailsValue), 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _descriptionController,
                                      decoration: InputDecoration(
                                        labelText: context.tr(
                                          'descriptionOptional',
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Book Button Section
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, buttonValue, child) {
                            return Opacity(
                              opacity: buttonValue,
                              child: Translations.get(
                                offset: Offset(0, 20 * (1 - buttonValue)),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _bookAppointment,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      context.tr('bookAppointmentButton'),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
        SnackBar(content: Text(context.tr('pleaseSelectServiceTimePetDoctor'))),
      );
      return;
    }

    if (_lat == null || _lng == null || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('pleaseSelectLocation'))),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('pleaseLoginFirst'))));
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
        SnackBar(content: Text(context.tr('pleaseCaptureYourLocation'))),
      );
      return;
    }

    // Driver assignment will be handled manually by admin or through separate assignment process
    final appointment = Appointment(
      ownerId: authProvider.user!.id!,
      petId: _selectedPet!.id!, // Use selected pet ID
      doctorId: _selectedDoctor!.id!, // Required doctor ID
      driverId: null, // No auto-assignment - driver must be assigned manually
      serviceType: _selectedService!.name,
      description: _descriptionController.text,
      scheduledAt: scheduledDateTime.toIso8601String(),
      address: _addressController.text,
      price: _selectedService!.price,
      urgencyLevel: _urgencyLevel,
      locationLat: _lat,
      locationLng: _lng,
      paymentMethod: _paymentMethod,
    );

    final success = await context.read<AppointmentProvider>().bookAppointment(
      appointment,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('appointmentBookedSuccessfully'))),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('failedToBookAppointment'))),
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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SelectLocationScreen()),
    );

    if (result != null) {
      setState(() {
        _addressController.text =
            '${result['address'] ?? ''} (${result['latitude']?.toStringAsFixed(5)}, ${result['longitude']?.toStringAsFixed(5)})';
        _lat = result['latitude'];
        _lng = result['longitude'];
      });
    }
  }
}

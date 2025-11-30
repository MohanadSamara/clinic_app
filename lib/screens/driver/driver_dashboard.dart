import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/location_service.dart';
import '../../models/appointment.dart';
import '../../models/driver_status.dart';
import '../../models/user.dart';
import '../../db/db_helper.dart';
import '../../components/modern_cards.dart';
import 'doctor_selection_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  List<Appointment> _assignedAppointments = [];
  DriverStatus? _currentStatus;
  User? _linkedDoctor;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _currentAddress;
  double? _driverLat;
  double? _driverLng;
  List<Marker> _markers = [];
  List<LatLng> _actualRoutePoints = [];
  List<LatLng> _plannedRoutePoints = [];
  List<Polyline> _appointmentPolylines = [];
  DateTime? _lastStatusUpdate;
  static const Duration _statusUpdateThrottle = Duration(seconds: 30);
  final Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _locationService.addListener(_onLocationChanged);
    _loadDriverData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _locationService.removeListener(_onLocationChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted && !_isDisposed) {
      setState(() {
        _driverLat = _locationService.currentPosition?.latitude;
        _driverLng = _locationService.currentPosition?.longitude;
        _updateMarkers();
        _checkAndUpdateStatusAutomatically();
      });
    }
  }

  Future<void> _loadDriverData() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id != null) {
      // Run database operations in parallel for better performance
      await Future.wait([
        _loadAssignedAppointments(),
        _loadDriverStatus(),
        _loadLinkedDoctor(),
      ]);

      // Load location separately as it may take longer (especially on web with API calls)
      _loadCurrentLocationAsync();
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentLocationAsync() async {
    try {
      await _loadCurrentLocation();
    } catch (e) {
      debugPrint('Error loading current location: $e');
    }
  }

  Future<void> _loadAssignedAppointments() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      final dbHelper = DBHelper.instance;
      List<Map<String, dynamic>> assignedAppointmentsData = [];

      // Check if driver is linked to a doctor
      if (authProvider.user?.linkedDoctorId == null) {
        // Driver is not linked to any doctor - show no appointments
        assignedAppointmentsData = [];
      } else {
        // Driver is linked to a doctor - get appointments for that doctor
        assignedAppointmentsData = await dbHelper.getAppointments(
          doctorId: authProvider.user!.linkedDoctorId!,
          hasLocation: true,
        );
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _assignedAppointments =
              assignedAppointmentsData
                  .map((a) => Appointment.fromMap(a))
                  .where(
                    (apt) =>
                        apt.status != 'completed' &&
                        apt.status != 'cancelled' &&
                        apt.locationLat != null &&
                        apt.locationLng != null,
                  )
                  .toList()
                ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          _updateMarkers();
        });

        // Start/stop tracking based on appointments
        if (_assignedAppointments.isNotEmpty && !_locationService.isTracking) {
          _locationService.startTracking();
        } else if (_assignedAppointments.isEmpty &&
            _locationService.isTracking) {
          _locationService.stopTracking();
        }
      }
    } catch (e) {
      debugPrint('Error loading assigned appointments: $e');
    }
  }

  Future<void> _loadDriverStatus() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      final dbHelper = DBHelper.instance;
      final statusData = await dbHelper.getDriverStatus(authProvider.user!.id!);
      if (statusData != null && mounted) {
        setState(() {
          _currentStatus = DriverStatus.fromMap(statusData);
        });
      } else {
        // Initialize driver status to 'available' if none exists
        await _initializeDriverStatus();
      }
    } catch (e) {
      debugPrint('Error loading driver status: $e');
    }
  }

  Future<void> _loadLinkedDoctor() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      if (authProvider.user?.linkedDoctorId != null) {
        final dbHelper = DBHelper.instance;
        final doctorData = await dbHelper.getUserById(
          authProvider.user!.linkedDoctorId!,
        );
        if (doctorData != null && mounted) {
          setState(() {
            _linkedDoctor = User.fromMap(doctorData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading linked doctor: $e');
    }
  }

  Future<void> _initializeDriverStatus() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      final position = await _locationService.getCurrentLocation();
      final dbHelper = DBHelper.instance;
      final driverStatus = DriverStatus(
        driverId: authProvider.user!.id!,
        latitude: position.latitude,
        longitude: position.longitude,
        status: 'available',
        lastUpdated: DateTime.now().toIso8601String(),
      );
      await dbHelper.insertDriverStatus(driverStatus.toMap());
      await _loadDriverStatus(); // Reload to get the inserted status
    } catch (e) {
      debugPrint('Error initializing driver status: $e');
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();

      // Create cache key for coordinates
      final cacheKey =
          '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}';

      String? address = _addressCache[cacheKey];

      if (address == null) {
        address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        // Cache the result
        if (address != null) {
          _addressCache[cacheKey] = address;
        }
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _driverLat = position.latitude;
          _driverLng = position.longitude;
          if (address != null &&
              address.startsWith('Address lookup not available on web')) {
            // Parse coordinates from error message
            final coordMatch = RegExp(
              r'Coordinates:\s*([0-9.-]+),\s*([0-9.-]+)',
            ).firstMatch(address);
            if (coordMatch != null) {
              _driverLat = double.tryParse(coordMatch.group(1)!);
              _driverLng = double.tryParse(coordMatch.group(2)!);
            }
            _currentAddress =
                'Location: ${_driverLat?.toStringAsFixed(6)}, ${_driverLng?.toStringAsFixed(6)}';
          } else {
            _currentAddress = address;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading current location: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _currentAddress = 'Location unavailable';
        });
      }
    }
  }

  void _checkAndUpdateStatusAutomatically() async {
    if (!mounted) return;
    // Throttle status updates to avoid excessive database operations
    final now = DateTime.now();
    if (_lastStatusUpdate != null &&
        now.difference(_lastStatusUpdate!) < _statusUpdateThrottle) {
      return;
    }

    if (_driverLat == null || _driverLng == null || _currentStatus == null)
      return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id == null) return;

    String newStatus = 'available';
    int? appointmentId;

    // Find the next appointment
    final nextAppointment = _assignedAppointments.isNotEmpty
        ? _assignedAppointments.first
        : null;

    if (nextAppointment != null &&
        nextAppointment.locationLat != null &&
        nextAppointment.locationLng != null) {
      final distance = _locationService.calculateDistance(
        _driverLat!,
        _driverLng!,
        nextAppointment.locationLat!,
        nextAppointment.locationLng!,
      );

      if (distance < 1.0) {
        // Within 1 km
        newStatus = 'arrived';
        appointmentId = nextAppointment.id;
      } else if (_locationService.isTracking) {
        newStatus = 'on_route';
        appointmentId = nextAppointment.id;
      }
    }

    // Only update if status changed
    if (newStatus != _currentStatus!.status) {
      try {
        _lastStatusUpdate = now;
        final dbHelper = DBHelper.instance;
        final driverStatus = DriverStatus(
          driverId: authProvider.user!.id!,
          latitude: _driverLat!,
          longitude: _driverLng!,
          status: newStatus,
          currentAppointmentId: appointmentId,
          lastUpdated: now.toIso8601String(),
        );

        await dbHelper.insertDriverStatus(driverStatus.toMap());
        await _loadDriverStatus();
      } catch (e) {
        debugPrint('Error updating status automatically: $e');
      }
    }
  }

  void _updateMarkers() {
    _markers.clear();
    _actualRoutePoints.clear();
    _plannedRoutePoints.clear();
    _appointmentPolylines.clear();

    if (_driverLat != null && _driverLng != null) {
      _markers.add(
        Marker(
          point: LatLng(_driverLat!, _driverLng!),
          child: GestureDetector(
            onTap: () => _showLocationInfo(
              'Your Location',
              _currentAddress ?? 'Current location',
            ),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Limit route points to last 50 for performance
    final routePoints = _locationService.routePoints;
    final startIndex = routePoints.length > 50 ? routePoints.length - 50 : 0;
    for (int i = startIndex; i < routePoints.length; i++) {
      _actualRoutePoints.add(
        LatLng(routePoints[i].latitude, routePoints[i].longitude),
      );
    }

    // Add markers for all appointments
    for (final appointment in _assignedAppointments) {
      if (appointment.locationLat != null && appointment.locationLng != null) {
        final isNext = appointment == _assignedAppointments.first;
        _markers.add(
          Marker(
            point: LatLng(appointment.locationLat!, appointment.locationLng!),
            child: GestureDetector(
              onTap: () => _showAppointmentInfo(appointment),
              child: Container(
                width: isNext ? 40 : 32,
                height: isNext ? 40 : 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isNext ? Colors.red : Colors.orange,
                    width: isNext ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isNext ? Colors.red : Colors.orange).withOpacity(
                        0.3,
                      ),
                      blurRadius: isNext ? 6 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on,
                  color: isNext ? Colors.red : Colors.orange,
                  size: isNext ? 24 : 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Add navigation route to next appointment only if driver location available
    if (_assignedAppointments.isNotEmpty &&
        _driverLat != null &&
        _driverLng != null) {
      final nextAppointment = _assignedAppointments.first;
      if (nextAppointment.locationLat != null &&
          nextAppointment.locationLng != null) {
        // Create a simple straight-line route for navigation
        _plannedRoutePoints.add(LatLng(_driverLat!, _driverLng!));
        _plannedRoutePoints.add(
          LatLng(nextAppointment.locationLat!, nextAppointment.locationLng!),
        );
      }
    }

    // Add polylines connecting appointments in sequence
    if (_assignedAppointments.length > 1) {
      for (int i = 0; i < _assignedAppointments.length - 1; i++) {
        final apt1 = _assignedAppointments[i];
        final apt2 = _assignedAppointments[i + 1];
        if (apt1.locationLat != null &&
            apt1.locationLng != null &&
            apt2.locationLat != null &&
            apt2.locationLng != null) {
          _appointmentPolylines.add(
            Polyline(
              points: [
                LatLng(apt1.locationLat!, apt1.locationLng!),
                LatLng(apt2.locationLat!, apt2.locationLng!),
              ],
              color: Colors.purple.shade600,
              strokeWidth: 3.0,
              borderColor: Theme.of(context).colorScheme.surface,
              borderStrokeWidth: 1.0,
            ),
          );
        }
      }
    }
  }

  String _calculateDistanceToAppointment(Appointment appointment) {
    if (_driverLat == null ||
        _driverLng == null ||
        appointment.locationLat == null ||
        appointment.locationLng == null) {
      return 'Distance unavailable';
    }
    final distance = _locationService.calculateDistance(
      _driverLat!,
      _driverLng!,
      appointment.locationLat!,
      appointment.locationLng!,
    );
    return '${distance.toStringAsFixed(1)} km away';
  }

  Future<void> _updateDriverStatus(String status, {int? appointmentId}) async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      final dbHelper = DBHelper.instance;

      // Get current location
      final position = await _locationService.getCurrentLocation();

      final driverStatus = DriverStatus(
        driverId: authProvider.user!.id!,
        latitude: position.latitude,
        longitude: position.longitude,
        status: status,
        currentAppointmentId: appointmentId,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      await dbHelper.insertDriverStatus(driverStatus.toMap());
      await _loadDriverStatus();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to: $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet2U Driver'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return IconButton(
                icon: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _showLanguageDialog(context, localeProvider),
                tooltip: 'Change Language',
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoctorSelectionScreen()),
            ),
            tooltip: 'Select Doctor',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadDriverData,
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, animationValue, child) {
          return Opacity(
            opacity: animationValue,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - animationValue)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Card (Uber-style)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, locationValue, child) {
                        return Opacity(
                          opacity: locationValue,
                          child: Transform.translate(
                            offset: Offset(-30 * (1 - locationValue), 0),
                            child: Card(
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Your Location',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _currentAddress ??
                                                'Getting location...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: Colors.blue,
                                      ),
                                      onPressed: _loadCurrentLocation,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Map View
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, mapValue, child) {
                        return Opacity(
                          opacity: mapValue,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - mapValue), 0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Live Map',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (_driverLat != null &&
                                        _driverLng != null)
                                      IconButton(
                                        icon: const Icon(Icons.my_location),
                                        onPressed: _centerOnCurrentLocation,
                                        tooltip: 'Center on my location',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: _loadCurrentLocation,
                                      tooltip: 'Refresh location',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 4,
                                  child: SizedBox(
                                    height: 400,
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          mapController: _mapController,
                                          options: MapOptions(
                                            initialCenter: _getMapCenter(),
                                            initialZoom: 13.0,
                                            onTap:
                                                (
                                                  _,
                                                  __,
                                                ) {}, // Enable tap interactions
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.example.clinic_app',
                                            ),
                                            PolylineLayer(
                                              polylines: [
                                                // Actual route path (driver's movement)
                                                if (_actualRoutePoints
                                                    .isNotEmpty)
                                                  Polyline(
                                                    points: _actualRoutePoints,
                                                    color: Colors.grey.shade600,
                                                    strokeWidth: 4.0,
                                                    borderColor: Theme.of(
                                                      context,
                                                    ).colorScheme.surface,
                                                    borderStrokeWidth: 1.0,
                                                  ),
                                                // Planned route to next appointment
                                                if (_plannedRoutePoints
                                                    .isNotEmpty)
                                                  Polyline(
                                                    points: _plannedRoutePoints,
                                                    color: Colors.blue.shade700,
                                                    strokeWidth: 6.0,
                                                    borderColor: Theme.of(
                                                      context,
                                                    ).colorScheme.surface,
                                                    borderStrokeWidth: 2.0,
                                                  ),
                                                // Appointment sequence polylines
                                                ..._appointmentPolylines,
                                              ],
                                            ),
                                            MarkerLayer(markers: _markers),
                                          ],
                                        ),
                                        // Map Legend
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (_driverLat != null &&
                                                    _driverLng != null)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.blue,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        'You',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                if (_driverLat != null &&
                                                    _driverLng != null)
                                                  const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Next Stop',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color:
                                                                Colors.orange,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Other Stops',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status Card
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      builder: (context, statusValue, child) {
                        return Opacity(
                          opacity: statusValue,
                          child: Transform.translate(
                            offset: Offset(-30 * (1 - statusValue), 0),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              color: Theme.of(context).colorScheme.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver Status',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          _currentStatus?.status ?? 'offline',
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            _currentStatus?.status ?? 'offline',
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        (_currentStatus?.status ?? 'offline')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(
                                            _currentStatus?.status ?? 'offline',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Status updates automatically based on location and activity.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Linked Doctor Card
                    if (_linkedDoctor != null) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 950),
                        builder: (context, doctorValue, child) {
                          return Opacity(
                            opacity: doctorValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - doctorValue), 0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                color: Theme.of(context).colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Linked Doctor',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Dr. ${_linkedDoctor!.name}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _linkedDoctor!.email,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      if (_linkedDoctor!.phone != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Phone: ${_linkedDoctor!.phone}',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),

                    // Next Appointment (Highlighted)
                    if (_assignedAppointments.isNotEmpty) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, appointmentValue, child) {
                          return Opacity(
                            opacity: appointmentValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - appointmentValue), 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next Appointment',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Card(
                                    color: Colors.orange.shade50,
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.orange,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _assignedAppointments
                                                          .first
                                                          .address ??
                                                      'Address not available',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Scheduled: ${_assignedAppointments.first.scheduledAt}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.info, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Status: ${_assignedAppointments.first.status}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.straighten,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _calculateDistanceToAppointment(
                                                  _assignedAppointments.first,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _navigateToAppointment(
                                                  _assignedAppointments.first,
                                                ),
                                            icon: const Icon(Icons.navigation),
                                            label: const Text('Navigate'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
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
                        },
                      ),
                      const SizedBox(height: 24),
                    ] else if (_linkedDoctor == null) ...[
                      // Show message for unlinked drivers
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, noAppointmentValue, child) {
                          return Opacity(
                            opacity: noAppointmentValue,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - noAppointmentValue), 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'No Appointments Available',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Card(
                                    color: Colors.grey.shade50,
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.link_off,
                                            size: 64,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Link with a Doctor',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'You need to link with a doctor to see appointments. Only linked drivers can view and manage appointments.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const DoctorSelectionScreen(),
                                                  ),
                                                ),
                                            icon: const Icon(Icons.person_add),
                                            label: const Text(
                                              'Link with Doctor',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
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
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // All Appointments
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1100),
                      builder: (context, allAppointmentsValue, child) {
                        return Opacity(
                          opacity: allAppointmentsValue,
                          child: Transform.translate(
                            offset: Offset(-30 * (1 - allAppointmentsValue), 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'All Appointments',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                if (_assignedAppointments.isEmpty)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_linkedDoctor == null) ...[
                                              const Icon(
                                                Icons.link_off,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'No doctor linked',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Link with a doctor to see appointments',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const DoctorSelectionScreen(),
                                                      ),
                                                    ),
                                                icon: const Icon(
                                                  Icons.person_add,
                                                ),
                                                label: const Text(
                                                  'Link with Doctor',
                                                ),
                                              ),
                                            ] else ...[
                                              const Icon(
                                                Icons.event_busy,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'No appointments assigned for today',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'For Dr. ${_linkedDoctor!.name}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _assignedAppointments.length,
                                    itemBuilder: (context, index) {
                                      final appointment =
                                          _assignedAppointments[index];
                                      final isNext = index == 0;
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        color: isNext
                                            ? Colors.grey.shade100
                                            : null,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: isNext
                                                ? Colors.orange
                                                : Colors.grey,
                                            child: Text('${index + 1}'),
                                          ),
                                          title: Text(
                                            'Appointment #${appointment.id}',
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Status: ${appointment.status}',
                                              ),
                                              Text(
                                                'Address: ${appointment.address}',
                                              ),
                                              Text(
                                                'Time: ${appointment.scheduledAt}',
                                              ),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.navigation),
                                            onPressed: () =>
                                                _navigateToAppointment(
                                                  appointment,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, actionsValue, child) {
                        return Opacity(
                          opacity: actionsValue,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - actionsValue), 0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    'Quick Actions',
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
                                ),

                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  children: [
                                    ModernGridCard(
                                      title: 'Vehicle Check',
                                      icon: Icons.directions_car,
                                      color: Colors.blue,
                                      onTap: () => _showVehicleCheckDialog(),
                                    ),
                                    ModernGridCard(
                                      title: 'Navigation',
                                      icon: Icons.navigation,
                                      color: Colors.green,
                                      onTap: () => _openNavigation(),
                                    ),
                                    ModernGridCard(
                                      title: 'Emergency',
                                      icon: Icons.emergency,
                                      color: Colors.red,
                                      onTap: () => _handleEmergency(),
                                    ),
                                    ModernGridCard(
                                      title: 'Support',
                                      icon: Icons.support_agent,
                                      color: Colors.purple,
                                      onTap: () => _contactSupport(),
                                    ),
                                  ],
                                ),
                              ],
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
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
      case 'on_route':
        return Colors.orange;
      case 'arrived':
        return Colors.blue;
      case 'offline':
      default:
        return Colors.grey;
    }
  }

  void _showVehicleCheckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vehicle Check'),
        content: const Text(
          'Vehicle check functionality will be implemented here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openNavigation() async {
    if (_driverLat != null && _driverLng != null) {
      await _launchNavigation(_driverLat!, _driverLng!, null, null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
    }
  }

  void _navigateToAppointment(Appointment appointment) async {
    if (_driverLat != null && _driverLng != null) {
      await _launchNavigation(
        _driverLat!,
        _driverLng!,
        appointment.locationLat,
        appointment.locationLng,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
    }
  }

  Future<void> _launchNavigation(
    double startLat,
    double startLng,
    double? destLat,
    double? destLng,
  ) async {
    String url;

    if (destLat != null && destLng != null) {
      // Navigation with destination
      url =
          'https://www.google.com/maps/dir/$startLat,$startLng/$destLat,$destLng';
    } else {
      // Just show current location
      url = 'https://www.google.com/maps/@$startLat,$startLng,15z';
    }

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback for web or if Google Maps not available
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open maps: $e')));
      }
    }
  }

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency'),
        content: const Text(
          'Emergency contact functionality will be implemented here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency alert sent!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact functionality will be implemented'),
      ),
    );
  }

  void _showLocationInfo(String title, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(address),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentInfo(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${appointment.serviceType}'),
            Text('Address: ${appointment.address ?? 'Not specified'}'),
            Text('Time: ${appointment.scheduledAt}'),
            Text('Status: ${appointment.status}'),
            if (appointment.locationLat != null &&
                appointment.locationLng != null)
              Text(
                'Coordinates: ${appointment.locationLat!.toStringAsFixed(4)}, ${appointment.locationLng!.toStringAsFixed(4)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAppointment(appointment);
            },
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate'),
          ),
        ],
      ),
    );
  }

  LatLng _getMapCenter() {
    final allLocations = <LatLng>[];

    // Add driver location if available
    if (_driverLat != null && _driverLng != null) {
      allLocations.add(LatLng(_driverLat!, _driverLng!));
    }

    // Add appointment locations
    for (final appointment in _assignedAppointments) {
      if (appointment.locationLat != null && appointment.locationLng != null) {
        allLocations.add(
          LatLng(appointment.locationLat!, appointment.locationLng!),
        );
      }
    }

    if (allLocations.isEmpty) {
      return const LatLng(31.963158, 35.930359); // Default to Amman, Jordan
    }

    // Calculate center of all locations
    double totalLat = 0;
    double totalLng = 0;
    for (final location in allLocations) {
      totalLat += location.latitude;
      totalLng += location.longitude;
    }
    return LatLng(
      totalLat / allLocations.length,
      totalLng / allLocations.length,
    );
  }

  void _centerOnCurrentLocation() {
    if (_driverLat != null && _driverLng != null) {
      _mapController.move(LatLng(_driverLat!, _driverLng!), 15.0);
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    LocaleProvider localeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.of(context).pop();
              },
              selected: localeProvider.locale.languageCode == 'en',
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: const Text('العربية'),
              onTap: () {
                localeProvider.setLocale(const Locale('ar'));
                Navigator.of(context).pop();
              },
              selected: localeProvider.locale.languageCode == 'ar',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

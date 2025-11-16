// lib/screens/owner/driver_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../db/db_helper.dart';
import '../../models/driver_status.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  List<DriverStatus> _driverStatuses = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadDriverStatuses();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverStatuses() async {
    if (!mounted) return;
    try {
      final dbHelper = DBHelper.instance;
      final driverStatusesData = await dbHelper.getAllDriverStatuses();

      if (mounted) {
        setState(() {
          _driverStatuses = driverStatusesData
              .map((data) => DriverStatus.fromMap(data))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading driver statuses: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverStatuses,
            tooltip: 'Refresh driver locations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _driverStatuses.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active drivers found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Driver status summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusSummary('Available', Colors.green),
                      _buildStatusSummary('On Route', Colors.orange),
                      _buildStatusSummary('Arrived', Colors.blue),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _getMapCenter(),
                      initialZoom: 12.0,
                      onTap: (_, __) {},
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.clinic_app',
                      ),
                      MarkerLayer(markers: _buildDriverMarkers()),
                    ],
                  ),
                ),
                // Driver list
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: _driverStatuses.length,
                    itemBuilder: (context, index) {
                      final driverStatus = _driverStatuses[index];
                      return Card(
                        margin: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    driverStatus.status,
                                  ).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: _getStatusColor(driverStatus.status),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Driver ${driverStatus.driverId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                driverStatus.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(driverStatus.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusSummary(String status, Color color) {
    final count = _driverStatuses
        .where((d) => d.status.toLowerCase() == status.toLowerCase())
        .length;
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(status, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  LatLng _getMapCenter() {
    if (_driverStatuses.isEmpty) {
      return const LatLng(31.963158, 35.930359); // Default to Amman, Jordan
    }

    // Calculate center of all driver locations
    double totalLat = 0;
    double totalLng = 0;
    for (final driver in _driverStatuses) {
      totalLat += driver.latitude;
      totalLng += driver.longitude;
    }
    return LatLng(
      totalLat / _driverStatuses.length,
      totalLng / _driverStatuses.length,
    );
  }

  List<Marker> _buildDriverMarkers() {
    return _driverStatuses.map((driverStatus) {
      return Marker(
        point: LatLng(driverStatus.latitude, driverStatus.longitude),
        child: GestureDetector(
          onTap: () => _showDriverInfo(driverStatus),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStatusColor(driverStatus.status),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(driverStatus.status).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car,
              color: _getStatusColor(driverStatus.status),
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showDriverInfo(DriverStatus driverStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Driver ${driverStatus.driverId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${driverStatus.status}'),
            Text(
              'Location: ${driverStatus.latitude.toStringAsFixed(4)}, ${driverStatus.longitude.toStringAsFixed(4)}',
            ),
            Text('Last Updated: ${driverStatus.lastUpdated}'),
            if (driverStatus.currentAppointmentId != null)
              Text(
                'Current Appointment: #${driverStatus.currentAppointmentId}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

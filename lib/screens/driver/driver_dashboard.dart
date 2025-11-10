import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/service_request_provider.dart';
import '../../models/service_request.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  LatLng? _currentLocation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<ServiceRequestProvider>();
    await provider.loadRequests(requestType: 'urgent', status: 'approved');
    await _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
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
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to determine location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceRequestProvider>();
    final requests = provider.requests
        .where((request) => request.requestType == 'urgent')
        .toList()
      ..sort((a, b) {
        final aDate = a.scheduledDate ?? a.requestDate;
        final bDate = b.scheduledDate ?? b.requestDate;
        return aDate.compareTo(bDate);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dispatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_locating)
            const LinearProgressIndicator(minHeight: 3),
          Expanded(
            flex: 2,
            child: requests.isEmpty
                ? const Center(
                    child: Text('No approved dispatches at the moment'),
                  )
                : _buildMap(requests),
          ),
          Expanded(
            flex: 3,
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('Pet #${request.petId} - ${request.requestType}'),
                    subtitle: Text(
                      'Scheduled: ${(request.scheduledDate ?? request.requestDate).toLocal()}\nAddress: ${request.address ?? 'Using GPS coordinates'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.navigation),
                      onPressed: () => _startNavigation(request),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<ServiceRequest> requests) {
    final points = <LatLng>[];
    for (final request in requests) {
      if (request.latitude != null && request.longitude != null) {
        points.add(LatLng(request.latitude!, request.longitude!));
      }
    }
    final center = points.isNotEmpty
        ? points.first
        : _currentLocation ?? const LatLng(31.9539, 35.9106);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.clinic_app',
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                child: const Icon(Icons.directions_car, color: Colors.blue),
              ),
            ],
          ),
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              for (int i = 0; i < points.length; i++)
                Marker(
                  point: points[i],
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 36),
                      Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_currentLocation, ...points]
                    .whereType<LatLng>()
                    .toList(),
                color: Colors.blueAccent,
                strokeWidth: 4,
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _startNavigation(ServiceRequest request) async {
    final lat = request.latitude;
    final lng = request.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not provided for this request'),
        ),
      );
      return;
    }
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch navigation')),
        );
      }
    }
  }
}

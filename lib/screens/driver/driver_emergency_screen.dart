import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/service_request.dart';
import '../../db/db_helper.dart';

import '../../components/modern_cards.dart';
import '../../../translations.dart';

class DriverEmergencyScreen extends StatefulWidget {
  const DriverEmergencyScreen({super.key});

  @override
  State<DriverEmergencyScreen> createState() => _DriverEmergencyScreenState();
}

class _DriverEmergencyScreenState extends State<DriverEmergencyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmergencyCases();
    });
  }

  Future<void> _loadEmergencyCases() async {
    final authProvider = context.read<AuthProvider>();
    final serviceRequestProvider = context.read<ServiceRequestProvider>();

    if (authProvider.user?.linkedDoctorId != null) {
      // Load emergency cases assigned to this driver's linked doctor
      await serviceRequestProvider.loadServiceRequests(
        assignedDoctorId: authProvider.user!.linkedDoctorId!,
        status: 'approved', // Only show approved emergency cases
        requestType: 'emergency',
      );
    }
  }

  Future<void> _startEmergencyResponse(ServiceRequest serviceRequest) async {
    final serviceRequestProvider = context.read<ServiceRequestProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();

    final success = await serviceRequestProvider.updateServiceRequestStatus(
      serviceRequest.id!,
      'in_progress',
    );

    // Also update the corresponding appointment status to 'in_progress'
    if (success && serviceRequest.id != null) {
      await DBHelper.instance.updateAppointmentStatusByServiceRequestId(
        serviceRequest.id!,
        'in_progress',
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('emergencyResponseStarted'))),
      );
      await _loadEmergencyCases(); // Refresh the list
      // Refresh appointments to show updated status on map
      await appointmentProvider.loadAppointments(
        doctorId: context.read<AuthProvider>().user!.linkedDoctorId!,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('failedToStartEmergencyResponse'))),
        );
      }
    }
  }

  Future<void> _completeEmergency(ServiceRequest serviceRequest) async {
    final serviceRequestProvider = context.read<ServiceRequestProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final success = await serviceRequestProvider.updateServiceRequestStatus(
      serviceRequest.id!,
      'completed',
    );

    // Also update the corresponding appointment status to 'completed'
    if (success && serviceRequest.id != null) {
      await DBHelper.instance.updateAppointmentStatusByServiceRequestId(
        serviceRequest.id!,
        'completed',
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('emergencyCaseCompleted'))),
      );
      await _loadEmergencyCases(); // Refresh the list
      // Refresh appointments to show updated status on map
      await appointmentProvider.loadAppointments(
        doctorId: context.read<AuthProvider>().user!.linkedDoctorId!,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('failedToCompleteEmergencyCase'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('emergencyCases')),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmergencyCases,
            tooltip: context.tr('refresh'),
          ),
        ],
      ),
      body: Consumer<ServiceRequestProvider>(
        builder: (context, serviceRequestProvider, child) {
          if (serviceRequestProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final emergencyCases = serviceRequestProvider.serviceRequests;

          if (emergencyCases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emergency_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noEmergencyCasesAssigned'),
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('emergencyCasesWillAppearHere'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: emergencyCases.length,
            itemBuilder: (context, index) {
              final serviceRequest = emergencyCases[index];
              return _EmergencyCaseCard(
                serviceRequest: serviceRequest,
                onStartResponse: () => _startEmergencyResponse(serviceRequest),
                onComplete: () => _completeEmergency(serviceRequest),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmergencyCaseCard extends StatelessWidget {
  final ServiceRequest serviceRequest;
  final VoidCallback onStartResponse;
  final VoidCallback onComplete;

  const _EmergencyCaseCard({
    required this.serviceRequest,
    required this.onStartResponse,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = serviceRequest.requestDate.toString().split(' ')[0];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.error.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with emergency indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: colorScheme.error, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('emergencyText'),
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pet and Owner Info
            Text(
              '${context.tr('petId')} ${serviceRequest.petId}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              serviceRequest.description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.8),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Location if available
            if (serviceRequest.address != null &&
                serviceRequest.address!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      serviceRequest.address!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(serviceRequest.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                serviceRequest.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(serviceRequest.status),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                if (serviceRequest.status == 'approved') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onStartResponse,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(context.tr('startResponse')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else if (serviceRequest.status == 'in_progress') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: Text(context.tr('complete')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Text(
                        '${context.tr('caseStatus')} ${serviceRequest.status}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/service_request.dart';
import '../../models/user.dart';
import '../../models/app_notification.dart';
import '../../db/db_helper.dart';

import '../../components/modern_cards.dart';

class EmergencyCasesScreen extends StatefulWidget {
  const EmergencyCasesScreen({super.key});

  @override
  State<EmergencyCasesScreen> createState() => _EmergencyCasesScreenState();
}

class _EmergencyCasesScreenState extends State<EmergencyCasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmergencyCases();
    });
  }

  Future<void> _loadEmergencyCases() async {
    final serviceRequestProvider = context.read<ServiceRequestProvider>();

    // Load ALL pending emergency cases for doctors to review and assign themselves to
    await serviceRequestProvider.loadServiceRequests(
      status: 'pending',
      requestType: 'emergency',
    );
  }

  Future<void> _approveCase(ServiceRequest serviceRequest) async {
    final authProvider = context.read<AuthProvider>();
    final serviceRequestProvider = context.read<ServiceRequestProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final success = await serviceRequestProvider.approveEmergencyCase(
      serviceRequest.id!,
      authProvider.user!.id!,
    );

    if (success && mounted) {
      // Notify linked driver
      await _notifyDriver(serviceRequest, notificationProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency case approved successfully')),
      );

      // Refresh the list
      await _loadEmergencyCases();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to approve case')));
      }
    }
  }

  Future<void> _rejectCase(ServiceRequest serviceRequest) async {
    final reason = await _showRejectionDialog();
    if (reason == null) return;

    final serviceRequestProvider = context.read<ServiceRequestProvider>();
    final success = await serviceRequestProvider.rejectEmergencyCase(
      serviceRequest.id!,
      reason,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emergency case rejected')));

      // Refresh the list
      await _loadEmergencyCases();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to reject case')));
      }
    }
  }

  Future<String?> _showRejectionDialog() async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Emergency Case'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Please provide a reason for rejection',
          ),
          onChanged: (value) => reason = value,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(reason),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyDriver(
    ServiceRequest serviceRequest,
    NotificationProvider notificationProvider,
  ) async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.linkedDriverId == null) return;

      // Get driver info
      final driverData = await DBHelper.instance.getUserById(
        authProvider.user!.linkedDriverId!,
      );
      if (driverData == null) return;

      final driver = User.fromMap(driverData);

      // Send notification to driver
      await notificationProvider.showImmediateNotification(
        title: 'New Emergency Case Assigned',
        body:
            'An emergency case has been approved and assigned to you. Please check your dashboard.',
        type: NotificationType.urgentCase,
        relatedId: serviceRequest.id.toString(),
        data: {
          'serviceRequestId': serviceRequest.id,
          'petId': serviceRequest.petId,
          'ownerId': serviceRequest.ownerId,
          'description': serviceRequest.description,
          'location': serviceRequest.address,
        },
      );

      debugPrint('Notification sent to driver: ${driver.name}');
    } catch (e) {
      debugPrint('Error notifying driver: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Cases'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmergencyCases,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ServiceRequestProvider>(
        builder: (context, serviceRequestProvider, child) {
          if (serviceRequestProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final urgentCases = serviceRequestProvider.getPendingEmergencyCases();

          if (urgentCases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending emergency cases',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All emergency cases have been handled',
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
            itemCount: urgentCases.length,
            itemBuilder: (context, index) {
              final serviceRequest = urgentCases[index];
              return _EmergencyCaseCard(
                serviceRequest: serviceRequest,
                onApprove: () => _approveCase(serviceRequest),
                onReject: () => _rejectCase(serviceRequest),
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
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _EmergencyCaseCard({
    required this.serviceRequest,
    required this.onApprove,
    required this.onReject,
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
            // Header with urgent indicator
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
                        'EMERGENCY',
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
              'Pet ID: ${serviceRequest.petId}',
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

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.error),
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}








import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/payment.dart';
import '../../components/ui_kit.dart';
import '../../services/pdf_service.dart';
import 'payment_processing_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id != null) {
      await context.read<PaymentProvider>().loadPayments(
        authProvider.user!.id!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = paymentProvider.payments;

          if (payments.isEmpty) {
            return EmptyState(
              icon: Icons.payment,
              title: 'No payments yet',
              message: 'Your payment history will appear here.',
            );
          }

          final stats = paymentProvider.getPaymentStats();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Paid',
                                'JOD ${stats['total_revenue']?.toStringAsFixed(2)}',
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Pending',
                                'JOD ${stats['total_pending']?.toStringAsFixed(2)}',
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Payment History
                Text(
                  'Payment History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showPaymentDetails(payment),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        payment.status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getStatusIcon(payment.status),
                                      color: _getStatusColor(payment.status),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          payment.serviceDescription,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Invoice: ${payment.invoiceNumber ?? 'N/A'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${payment.currency} ${payment.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _getStatusColor(
                                            payment.status,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(payment.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (payment.status == 'pending' ||
                                  payment.status == 'processing') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _processPayment(payment),
                                    icon: const Icon(Icons.payment),
                                    label: Text(
                                      payment.status == 'processing'
                                          ? 'Continue Payment'
                                          : 'Complete Payment',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'refunded':
        return Colors.purple;
      case 'partially_refunded':
        return Colors.deepPurple;
      case 'disputed':
        return Colors.amber;
      case 'expired':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.hourglass_top;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.undo;
      case 'partially_refunded':
        return Icons.undo_rounded;
      case 'disputed':
        return Icons.warning;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(payment.status),
                      color: _getStatusColor(payment.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice ${payment.invoiceNumber ?? 'N/A'}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(payment.createdAt),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Service Details
              Text(
                'Service Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(payment.serviceDescription),

              const SizedBox(height: 24),

              // Payment Breakdown
              Text(
                'Payment Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildBreakdownRow('Subtotal', payment.subtotal),
              _buildBreakdownRow('Tax (16%)', payment.tax),
              const Divider(),
              _buildBreakdownRow('Total', payment.total, isTotal: true),

              const SizedBox(height: 24),

              // Payment Info
              Text(
                'Payment Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildInfoRow('Method', payment.method),
              _buildInfoRow('Status', payment.status.toUpperCase()),
              if (payment.transactionId.isNotEmpty)
                _buildInfoRow('Transaction ID', payment.transactionId),
              if (payment.completedAt != null)
                _buildInfoRow('Completed', _formatDate(payment.completedAt!)),

              const SizedBox(height: 24),

              // Actions
              if (payment.status == 'pending' ||
                  payment.status == 'processing') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _processPayment(payment);
                    },
                    icon: const Icon(Icons.payment),
                    label: Text(
                      payment.status == 'processing'
                          ? 'Continue Payment'
                          : 'Complete Payment',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (payment.isCompleted || payment.isPartiallyRefunded) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadInvoice(payment),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Invoice'),
                  ),
                ),
                const SizedBox(height: 12),
                if (payment.canBeRefunded) ...[
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _requestRefund(payment),
                      icon: const Icon(Icons.undo),
                      label: const Text('Request Refund'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              if (payment.status == 'failed') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _retryPayment(payment);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Payment'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (payment.status == 'disputed') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _contactSupport(payment),
                    icon: const Icon(Icons.support),
                    label: const Text('Contact Support'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          const Spacer(),
          Text(
            '${Payment.fromMap({}).currency} ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(Payment payment) async {
    // Navigate to payment processing screen
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(payment: payment),
      ),
    );

    if (result == true) {
      // Refresh payments
      _loadPayments();
    }
  }

  Future<void> _downloadInvoice(Payment payment) async {
    try {
      // Generate and save the PDF
      final filePath = await PdfService.generateInvoicePdf(payment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice downloaded successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                // Try to open the file (this will work on mobile)
                // On desktop, users can find it in their documents folder
                try {
                  await PdfService.shareInvoicePdf(payment);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File saved to Documents folder'),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _requestRefund(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: const Text(
          'Are you sure you want to request a refund for this payment? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processRefund(payment);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Request Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(Payment payment) async {
    final success = await context.read<PaymentProvider>().processRefund(
      paymentId: payment.id!,
      reason: 'Customer requested refund',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Refund request submitted successfully'
                : 'Failed to process refund request',
          ),
        ),
      );

      if (success) {
        _loadPayments();
      }
    }
  }

  void _retryPayment(Payment payment) {
    // Navigate to payment processing screen for retry
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(payment: payment),
      ),
    );
  }

  void _contactSupport(Payment payment) {
    // TODO: Implement support contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Support contact feature coming soon. Please call our support line.',
        ),
      ),
    );
  }
}

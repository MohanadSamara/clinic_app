// lib/screens/owner/payment_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';
import '../../models/payment.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    await context.read<PaymentProvider>().loadOwnerPayments(userId);
    await context.read<AppointmentProvider>().loadAppointments(ownerId: userId);
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final outstanding = paymentProvider.unpaidAppointments;
    final payments = paymentProvider.payments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Outstanding balance',
                    value: paymentProvider.totalOutstanding(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total paid',
                    value: paymentProvider.totalPaid(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Outstanding invoices',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (paymentProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (outstanding.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.verified_outlined, color: Colors.green),
                  title: Text('All appointments are paid.'),
                ),
              )
            else
              ...outstanding.map((appointment) => _OutstandingTile(
                    appointment: appointment,
                    onPayNow: () => _showPaymentDialog(appointment),
                  )),
            const SizedBox(height: 24),
            Text(
              'Payment history',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('No payments recorded yet'),
                ),
              )
            else
              ...payments.map((payment) => _PaymentTile(payment: payment)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(Appointment appointment) async {
    final intent = await showDialog<_PaymentIntent>(
      context: context,
      builder: (context) => _PaymentDialog(appointment: appointment),
    );

    if (intent != null) {
      final provider = context.read<PaymentProvider>();
      final txnId =
          'txn-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
      await provider.recordPayment(
        appointmentId: appointment.id!,
        amount: intent.amount,
        method: intent.method,
        transactionId: txnId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
      await _loadData();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'String.fromCharCode(36)${value.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutstandingTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onPayNow;

  const _OutstandingTile({
    required this.appointment,
    required this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final scheduled = DateTime.tryParse(appointment.scheduledAt)?.toLocal();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt),
        title: Text(appointment.serviceType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scheduled != null)
              Text('Scheduled ${scheduled.toString().split('.').first}')
            else
              Text('Appointment #${appointment.id}'),
            Text('Amount due: String.fromCharCode(36)${(appointment.price ?? 0).toStringAsFixed(2)}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onPayNow,
          child: const Text('Pay now'),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(payment.createdAt)?.toLocal();
    return Card(
      child: ListTile(
        leading: Icon(
          payment.status == 'completed'
              ? Icons.check_circle_outline
              : Icons.pending,
          color: payment.status == 'completed' ? Colors.green : Colors.orange,
        ),
        title: Text('String.fromCharCode(36)${payment.amount.toStringAsFixed(2)} • ${payment.method}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (createdAt != null)
              Text('Paid ${createdAt.toString().split('.').first}')
            else
              Text('Transaction ${payment.transactionId}'),
            if (payment.serviceType != null)
              Text(payment.serviceType!),
          ],
        ),
      ),
    );
  }
}

class _PaymentIntent {
  final String method;
  final double amount;

  _PaymentIntent({required this.method, required this.amount});
}

class _PaymentDialog extends StatefulWidget {
  final Appointment appointment;

  const _PaymentDialog({required this.appointment});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _method = 'online';

  @override
  Widget build(BuildContext context) {
    final amount = widget.appointment.price ?? 0;
    return AlertDialog(
      title: const Text('Confirm payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(widget.appointment.serviceType),
            subtitle: Text('Amount String.fromCharCode(36)${amount.toStringAsFixed(2)}'),
          ),
          RadioListTile<String>(
            value: 'online',
            groupValue: _method,
            onChanged: (value) => setState(() => _method = value ?? 'online'),
            title: const Text('Online payment'),
          ),
          RadioListTile<String>(
            value: 'card',
            groupValue: _method,
            onChanged: (value) => setState(() => _method = value ?? 'card'),
            title: const Text('Card on delivery'),
          ),
          RadioListTile<String>(
            value: 'cash',
            groupValue: _method,
            onChanged: (value) => setState(() => _method = value ?? 'cash'),
            title: const Text('Cash'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            _PaymentIntent(method: _method, amount: amount),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

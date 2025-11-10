import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _currency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoices();
    });
  }

  Future<void> _loadInvoices() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      await context
          .read<PaymentProvider>()
          .loadInvoicesForOwner(auth.user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Payments')),
      body: RefreshIndicator(
        onRefresh: _loadInvoices,
        child: Consumer<PaymentProvider>(
          builder: (context, paymentProvider, child) {
            if (paymentProvider.isLoadingInvoices) {
              return const Center(child: CircularProgressIndicator());
            }

            final invoices = paymentProvider.invoices;
            if (invoices.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No invoices yet. Book a service to generate billing records.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final outstanding = invoices
                .where((invoice) => !invoice.isPaid)
                .fold<double>(0, (sum, invoice) => sum + invoice.balance);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Outstanding balance'),
                    subtitle: const Text('Total due across unpaid invoices'),
                    trailing: Text(
                      _currency.format(outstanding),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...invoices.map((invoice) => _InvoiceCard(
                      invoice: invoice,
                      currency: _currency,
                      onPay: invoice.isPaid
                          ? null
                          : () => _promptPayment(context, invoice),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _promptPayment(
    BuildContext context,
    InvoiceSummary invoice,
  ) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Pay with card'),
                onTap: () => Navigator.of(context).pop('card'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Online banking'),
                onTap: () => Navigator.of(context).pop('online'),
              ),
              ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Mobile wallet'),
                onTap: () => Navigator.of(context).pop('wallet'),
              ),
            ],
          ),
        );
      },
    );

    if (method == null) return;
    final auth = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    final transactionId =
        'txn-${invoice.appointmentId}-${DateTime.now().millisecondsSinceEpoch}';

    final paymentId = await paymentProvider.recordPayment(
      appointmentId: invoice.appointmentId,
      amount: invoice.balance,
      method: method,
      transactionId: transactionId,
    );

    if (paymentId > 0) {
      if (auth.user?.id != null) {
        await paymentProvider.loadInvoicesForOwner(auth.user!.id!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed to process')),
        );
      }
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceSummary invoice;
  final NumberFormat currency;
  final VoidCallback? onPay;

  const _InvoiceCard({
    required this.invoice,
    required this.currency,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    invoice.serviceType,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(invoice.isPaid ? 'Paid' : 'Unpaid'),
                  backgroundColor:
                      invoice.isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Appointment #${invoice.appointmentId}'),
            Text('Scheduled: ${DateFormat('yMMMd – jm').format(invoice.scheduledAt)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${currency.format(invoice.totalAmount)}'),
                      Text('Paid: ${currency.format(invoice.amountPaid)}'),
                      Text('Balance: ${currency.format(invoice.balance)}'),
                    ],
                  ),
                ),
                if (onPay != null)
                  ElevatedButton(
                    onPressed: onPay,
                    child: const Text('Pay now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

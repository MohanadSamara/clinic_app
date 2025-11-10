class InvoiceSummary {
  final int appointmentId;
  final String serviceType;
  final DateTime scheduledAt;
  final double totalAmount;
  final double amountPaid;
  final String status;
  final double balance;

  InvoiceSummary({
    required this.appointmentId,
    required this.serviceType,
    required this.scheduledAt,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
  }) : balance = totalAmount - amountPaid;

  factory InvoiceSummary.fromMap(Map<String, dynamic> map) {
    final total = (map['price'] as num?)?.toDouble() ?? 0.0;
    final paid = (map['amount_paid'] as num?)?.toDouble() ?? 0.0;
    return InvoiceSummary(
      appointmentId: map['appointment_id'],
      serviceType: map['service_type'] ?? 'Service',
      scheduledAt: DateTime.tryParse(map['scheduled_at'] ?? '') ?? DateTime.now(),
      totalAmount: total,
      amountPaid: paid,
      status: map['status'] ?? 'pending',
    );
  }

  bool get isPaid => balance <= 0.01;
}

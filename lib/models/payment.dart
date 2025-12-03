// lib/models/payment.dart
class Payment {
  final int? id;
  final int appointmentId;
  final int userId; // Owner who made the payment
  final double subtotal;
  final double tax;
  final double total;
  final String currency;
  final String method; // 'card', 'cash', 'online'
  final String
  status; // 'pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded', 'partially_refunded', 'disputed', 'expired'
  final String transactionId;
  final String? paymentIntentId; // For online payments
  final String? invoiceNumber;
  final String serviceDescription;
  final String createdAt;
  final String? completedAt;

  Payment({
    this.id,
    required this.appointmentId,
    required this.userId,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.currency = 'JOD',
    required this.method,
    this.status = 'pending',
    required this.transactionId,
    this.paymentIntentId,
    this.invoiceNumber,
    required this.serviceDescription,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'appointment_id': appointmentId,
    'user_id': userId,
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'currency': currency,
    'method': method,
    'status': status,
    'transaction_id': transactionId,
    'payment_intent_id': paymentIntentId,
    'invoice_number': invoiceNumber,
    'service_description': serviceDescription,
    'created_at': createdAt,
    'completed_at': completedAt,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'] is int ? m['id'] as int : null,
    appointmentId: m['appointment_id'] is int ? m['appointment_id'] as int : 0,
    userId: m['user_id'] is int ? m['user_id'] as int : 0,
    subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0.0,
    tax: (m['tax'] as num?)?.toDouble() ?? 0.0,
    total: (m['total'] as num?)?.toDouble() ?? 0.0,
    currency: m['currency'] ?? 'JOD',
    method: m['method'] ?? '',
    status: m['status'] ?? 'pending',
    transactionId: m['transaction_id'] ?? '',
    paymentIntentId: m['payment_intent_id'],
    invoiceNumber: m['invoice_number'],
    serviceDescription: m['service_description'] ?? '',
    createdAt: m['created_at'] ?? '',
    completedAt: m['completed_at'],
  );

  // Helper getters
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isRefunded => status == 'refunded';
  bool get isPartiallyRefunded => status == 'partially_refunded';
  bool get isDisputed => status == 'disputed';
  bool get isExpired => status == 'expired';

  // Composite getters
  bool get isSuccessful => status == 'completed';
  bool get isFinal =>
      ['completed', 'failed', 'cancelled', 'expired'].contains(status);
  bool get canBeRefunded =>
      ['completed', 'partially_refunded'].contains(status);
  bool get isActive => ['pending', 'processing'].contains(status);

  // Generate invoice number
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  Payment copyWith({
    int? id,
    int? appointmentId,
    int? userId,
    double? subtotal,
    double? tax,
    double? total,
    String? currency,
    String? method,
    String? status,
    String? transactionId,
    String? paymentIntentId,
    String? invoiceNumber,
    String? serviceDescription,
    String? createdAt,
    String? completedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId ?? this.userId,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

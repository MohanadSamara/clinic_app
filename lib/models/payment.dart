// lib/models/payment.dart
class Payment {
  final int? id;
  final int appointmentId;
  final double amount;
  final String method; // 'card', 'cash', 'online'
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String transactionId;
  final String createdAt;

  Payment({
    this.id,
    required this.appointmentId,
    required this.amount,
    required this.method,
    this.status = 'pending',
    required this.transactionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'appointment_id': appointmentId,
    'amount': amount,
    'method': method,
    'status': status,
    'transaction_id': transactionId,
    'created_at': createdAt,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'],
    appointmentId: m['appointment_id'],
    amount: (m['amount'] as num).toDouble(),
    method: m['method'] ?? '',
    status: m['status'] ?? 'pending',
    transactionId: m['transaction_id'] ?? '',
    createdAt: m['created_at'] ?? '',
  );
}

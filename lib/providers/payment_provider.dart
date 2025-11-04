// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../db/db_helper.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  Future<int> recordPayment({
    required int appointmentId,
    required double amount,
    required String method, // e.g., 'card', 'cash', 'online'
    String status = 'completed', // 'pending', 'completed', 'failed', 'refunded'
    required String transactionId,
    DateTime? createdAt,
  }) async {
    final id = await DBHelper.instance.insertPayment({
      'appointment_id': appointmentId,
      'amount': amount,
      'method': method,
      'status': status,
      'transaction_id': transactionId,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    });
    return id;
  }

  Future<bool> processRefund({
    required int appointmentId,
    double? amount,
    String? reason,
  }) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final payments = await DBHelper.instance.getPaymentsByAppointment(
        appointmentId,
      );
      if (payments.isEmpty) {
        debugPrint('No payments found for appointment $appointmentId');
        return false;
      }

      // Prefer last 'completed' payment, fallback to last record
      Map<String, dynamic>? completed;
      for (final p in payments) {
        if ((p['status'] ?? '') == 'completed') {
          completed = p;
          break;
        }
      }
      completed ??= payments.first;

      final originalAmount = (completed['amount'] as num).toDouble().abs();
      final refundAmount = amount ?? originalAmount;
      final baseTxn = (completed['transaction_id'] ?? 'txn').toString();
      final refundTxnId =
          'refund-$baseTxn-${DateTime.now().millisecondsSinceEpoch}';

      await DBHelper.instance.insertPayment({
        'appointment_id': appointmentId,
        'amount': -refundAmount,
        'method': 'refund',
        'status': 'refunded',
        'transaction_id': refundTxnId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Optional: log audit as notification entry (type: 'audit')
      await DBHelper.instance.insertNotification({
        'user_id': 0, // system actor
        'title': 'Refund processed',
        'message':
            'Refund for appointment #$appointmentId amount: $refundAmount. ${reason ?? ''}'
                .trim(),
        'type': 'audit',
        'is_read': 1,
        'created_at': DateTime.now().toIso8601String(),
        'data': null,
      });

      return true;
    } catch (e) {
      debugPrint('Error processing refund for appointment $appointmentId: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}

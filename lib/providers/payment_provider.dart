// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../db/db_helper.dart';
import '../models/payment.dart';
import '../models/appointment.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isProcessing = false;
  bool _isLoading = false;
  List<Payment> _payments = [];
  List<Appointment> _unpaidAppointments = [];

  bool get isProcessing => _isProcessing;
  bool get isLoading => _isLoading;
  List<Payment> get payments => _payments;
  List<Appointment> get unpaidAppointments => _unpaidAppointments;

  Future<void> loadOwnerPayments(int ownerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final paymentRows = await DBHelper.instance.getPaymentsByOwner(ownerId);
      _payments = paymentRows.map((row) => Payment.fromMap(row)).toList();

      final appointmentRows = await DBHelper.instance.getAppointments(
        ownerId: ownerId,
      );
      final paidAppointmentIds = _payments
          .where((p) => p.status != 'failed')
          .map((p) => p.appointmentId)
          .toSet();

      _unpaidAppointments = appointmentRows
          .map((row) => Appointment.fromMap(row))
          .where((appointment) {
        final price = appointment.price ?? 0;
        final relevantStatus = appointment.status == 'completed' ||
            appointment.status == 'confirmed' ||
            appointment.status == 'in_progress' ||
            appointment.status == 'rescheduled';
        return price > 0 && relevantStatus &&
            !paidAppointmentIds.contains(appointment.id);
      }).toList();
    } catch (e) {
      debugPrint('Error loading owner payments: $e');
      _payments = [];
      _unpaidAppointments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> recordPayment({
    required int appointmentId,
    required double amount,
    required String method, // e.g., 'card', 'cash', 'online'
    String status = 'completed', // 'pending', 'completed', 'failed', 'refunded'
    required String transactionId,
    DateTime? createdAt,
  }) async {
    final timestamp = (createdAt ?? DateTime.now()).toIso8601String();
    final id = await DBHelper.instance.insertPayment({
      'appointment_id': appointmentId,
      'amount': amount,
      'method': method,
      'status': status,
      'transaction_id': transactionId,
      'created_at': timestamp,
    });
    _payments.insert(
      0,
      Payment(
        id: id,
        appointmentId: appointmentId,
        amount: amount,
        method: method,
        status: status,
        transactionId: transactionId,
        createdAt: timestamp,
      ),
    );
    _unpaidAppointments.removeWhere((apt) => apt.id == appointmentId);
    notifyListeners();
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

  double totalPaid() {
    return _payments
        .where((payment) => payment.status == 'completed')
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double totalOutstanding() {
    return _unpaidAppointments.fold(
      0.0,
      (sum, appointment) => sum + (appointment.price ?? 0),
    );
  }
}

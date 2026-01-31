// lib/providers/payment_provider.dart
// Payment Provider using Firestore as the single source of truth
// All data synced globally across devices
// OTP Authentication remains UNCHANGED

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../models/appointment.dart';
import 'appointment_provider.dart';

class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  bool _isProcessing = false;
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper to convert any ID to String
  String _toStringId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is int) return id.toString();
    return id.toString();
  }

  // Helper to convert any ID to int
  int _toIntId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String) {
      return int.tryParse(id) ?? id.hashCode;
    }
    return id.hashCode;
  }

  // ========== LOAD DATA ==========

  Future<void> loadPayments(dynamic userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userIdStr = _toStringId(userId);
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userIdStr)
          .orderBy('createdAt', descending: true)
          .get();

      _payments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = _toIntId(doc.id);
        return Payment.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading payments: $e');
      _error = 'Error loading payments: $e';
      _payments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CREATE PAYMENT ==========

  Future<Payment?> createPayment({
    required dynamic appointmentId,
    required dynamic userId,
    required double subtotal,
    required String serviceDescription,
    String currency = 'JOD',
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Calculate tax (16% VAT in Jordan)
      final tax = subtotal * 0.16;
      final total = subtotal + tax;

      final appointmentIdInt = _toIntId(appointmentId);
      final userIdInt = _toIntId(userId);

      final payment = Payment(
        appointmentId: appointmentIdInt,
        userId: userIdInt,
        subtotal: subtotal,
        tax: tax,
        total: total,
        currency: currency,
        method: 'pending',
        transactionId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: Payment.generateInvoiceNumber(),
        serviceDescription: serviceDescription,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Add to Firestore
      final docRef = await _firestore.collection('payments').add({
        'appointmentId': _toStringId(appointmentId),
        'userId': _toStringId(userId),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'currency': currency,
        'method': 'pending',
        'transactionId': payment.transactionId,
        'invoiceNumber': payment.invoiceNumber,
        'serviceDescription': serviceDescription,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await docRef.update({'id': docRef.id});

      final newPayment = payment.copyWith(id: _toIntId(docRef.id));

      _payments.insert(0, newPayment);
      notifyListeners();

      return newPayment;
    } catch (e) {
      debugPrint('Error creating payment: $e');
      _error = 'Error creating payment: $e';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ========== PROCESS ONLINE PAYMENT ==========

  Future<bool> processOnlinePayment({
    required dynamic paymentId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation
      if (cardNumber.length < 16 || cvv.length < 3) {
        throw Exception('Invalid card details');
      }

      // Generate transaction ID
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final paymentIntentId = 'pi_${DateTime.now().millisecondsSinceEpoch}';

      final paymentIdStr = _toStringId(paymentId);

      // Update payment in Firestore
      await _firestore.collection('payments').doc(paymentIdStr).update({
        'method': 'card',
        'status': 'completed',
        'transactionId': transactionId,
        'paymentIntentId': paymentIntentId,
        'completedAt': DateTime.now().toIso8601String(),
      });

      // Update local payment
      final paymentIdInt = _toIntId(paymentId);
      final index = _payments.indexWhere((p) => p.id == paymentIdInt);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(
          method: 'card',
          status: 'completed',
          transactionId: transactionId,
          paymentIntentId: paymentIntentId,
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      // Update appointment status to 'paid'
      final appointmentProvider = AppointmentProvider();
      final appointmentId = _payments[index].appointmentId;
      if (appointmentId != null && appointmentId > 0) {
        await appointmentProvider.updateAppointmentStatus(
          appointmentId,
          'paid',
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing online payment: $e');
      _error = 'Payment failed: $e';

      final paymentIdStr = _toStringId(paymentId);
      // Update payment status to failed
      await _firestore.collection('payments').doc(paymentIdStr).update({
        'status': 'failed',
        'completedAt': DateTime.now().toIso8601String(),
      });

      final paymentIdInt = _toIntId(paymentId);
      final index = _payments.indexWhere((p) => p.id == paymentIdInt);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(
          status: 'failed',
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ========== PROCESS CASH PAYMENT ==========

  Future<bool> processCashPayment(dynamic paymentId) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final transactionId = 'cash_${DateTime.now().millisecondsSinceEpoch}';
      final paymentIdStr = _toStringId(paymentId);

      await _firestore.collection('payments').doc(paymentIdStr).update({
        'method': 'cash',
        'status': 'completed',
        'transactionId': transactionId,
        'completedAt': DateTime.now().toIso8601String(),
      });

      final paymentIdInt = _toIntId(paymentId);
      final index = _payments.indexWhere((p) => p.id == paymentIdInt);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(
          method: 'cash',
          status: 'completed',
          transactionId: transactionId,
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing cash payment: $e');
      _error = 'Payment failed: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ========== GET PAYMENT BY ID ==========

  Payment? getPaymentById(dynamic paymentId) {
    final paymentIdInt = _toIntId(paymentId);
    try {
      return _payments.firstWhere((p) => p.id == paymentIdInt);
    } catch (e) {
      return null;
    }
  }

  // ========== GET PAYMENTS BY APPOINTMENT ==========

  Future<List<Payment>> getPaymentsByAppointment(dynamic appointmentId) async {
    try {
      final appointmentIdStr = _toStringId(appointmentId);
      final snapshot = await _firestore
          .collection('payments')
          .where('appointmentId', isEqualTo: appointmentIdStr)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = _toIntId(doc.id);
        return Payment.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting payments by appointment: $e');
      return [];
    }
  }

  // ========== PROCESS REFUND ==========

  Future<bool> processRefund({
    required dynamic paymentId,
    double? amount,
    String? reason,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final paymentIdInt = _toIntId(paymentId);
      final payment = getPaymentById(paymentIdInt);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      if (!payment.isCompleted) {
        throw Exception('Can only refund completed payments');
      }

      final refundAmount = amount ?? payment.total;
      final refundTxnId =
          'refund_${payment.transactionId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create refund payment record in Firestore
      await _firestore.collection('payments').add({
        'appointmentId': payment.appointmentId.toString(),
        'userId': payment.userId.toString(),
        'subtotal': -refundAmount,
        'tax': 0.0,
        'total': -refundAmount,
        'currency': payment.currency,
        'method': 'refund',
        'status': 'refunded',
        'transactionId': refundTxnId,
        'invoiceNumber': 'REF-${payment.invoiceNumber}',
        'serviceDescription': 'Refund for ${payment.serviceDescription}',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': DateTime.now().toIso8601String(),
      });

      // Update original payment status if full refund
      if (amount == null || amount >= payment.total) {
        final paymentIdStr = _toStringId(paymentId);
        await _firestore.collection('payments').doc(paymentIdStr).update({
          'status': 'refunded',
        });

        final index = _payments.indexWhere((p) => p.id == paymentIdInt);
        if (index != -1) {
          _payments[index] = _payments[index].copyWith(status: 'refunded');
        }

        // Update appointment status to 'refunded'
        final appointmentProvider = AppointmentProvider();
        if (payment.appointmentId != null && payment.appointmentId > 0) {
          await appointmentProvider.updateAppointmentStatus(
            payment.appointmentId!,
            'refunded',
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      _error = 'Refund failed: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ========== STATISTICS ==========

  Map<String, dynamic> getPaymentStats() {
    final completed = _payments.where((p) => p.isCompleted).toList();
    final pending = _payments.where((p) => p.isPending).toList();
    final failed = _payments.where((p) => p.isFailed).toList();

    final totalRevenue = completed.fold<double>(0, (sum, p) => sum + p.total);
    final totalPending = pending.fold<double>(0, (sum, p) => sum + p.total);

    return {
      'total_payments': _payments.length,
      'completed_payments': completed.length,
      'pending_payments': pending.length,
      'failed_payments': failed.length,
      'total_revenue': totalRevenue,
      'total_pending': totalPending,
    };
  }

  // ========== CLEAR ==========

  void clearPayments() {
    _payments.clear();
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

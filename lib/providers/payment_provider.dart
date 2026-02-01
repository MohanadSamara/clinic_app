// lib/providers/payment_provider.dart
// Payment Provider using Supabase as the single source of truth
// All data synced globally across devices
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/payment.dart';
import '../models/appointment.dart';
import 'appointment_provider.dart';

/// PaymentProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: payments, appointments
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  bool _isProcessing = false;
  bool _isLoading = false;
  String? _error;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<Payment> get payments => _payments;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== LOAD DATA ==========

  Future<void> loadPayments(dynamic userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userIdStr = userId?.toString() ?? '';

      final paymentsData = await _supabaseService.getPaymentsByUser(userIdStr);

      _payments = paymentsData.map((data) {
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

      final appointmentIdStr = appointmentId?.toString() ?? '';
      final userIdStr = userId?.toString() ?? '';

      final paymentData = {
        'appointment_id': appointmentIdStr,
        'user_id': userIdStr,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'currency': currency,
        'method': 'pending',
        'transaction_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'invoice_number': Payment.generateInvoiceNumber(),
        'service_description': serviceDescription,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final paymentId = await _supabaseService.insertPayment(paymentData);

      final payment = Payment(
        id: paymentId,
        appointmentId: appointmentIdStr,
        userId: userIdStr,
        subtotal: subtotal,
        tax: tax,
        total: total,
        currency: currency,
        method: 'pending',
        transactionId: paymentData['transaction_id'] as String,
        invoiceNumber: paymentData['invoice_number'] as String,
        serviceDescription: serviceDescription,
        createdAt: paymentData['created_at'] as String,
      );

      _payments.insert(0, payment);
      notifyListeners();

      return payment;
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

      final paymentIdStr = paymentId?.toString() ?? '';

      // Update payment in Supabase
      await _supabaseService.updatePayment(paymentIdStr, {
        'method': 'card',
        'status': 'completed',
        'transaction_id': transactionId,
        'payment_intent_id': paymentIntentId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Update local payment
      final index = _payments.indexWhere((p) => p.id == paymentIdStr);
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
      final appointmentIdStr = _payments[index].appointmentId;
      if (appointmentIdStr != null && appointmentIdStr.isNotEmpty) {
        final appointmentIdInt =
            int.tryParse(appointmentIdStr) ?? appointmentIdStr.hashCode;
        await appointmentProvider.updateAppointmentStatus(
          appointmentIdInt,
          'paid',
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing online payment: $e');
      _error = 'Payment failed: $e';

      final paymentIdStr = paymentId?.toString() ?? '';
      // Update payment status to failed
      await _supabaseService.updatePayment(paymentIdStr, {
        'status': 'failed',
        'completed_at': DateTime.now().toIso8601String(),
      });

      final index = _payments.indexWhere((p) => p.id == paymentIdStr);
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
      final paymentIdStr = paymentId?.toString() ?? '';

      await _supabaseService.updatePayment(paymentIdStr, {
        'method': 'cash',
        'status': 'completed',
        'transaction_id': transactionId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      final index = _payments.indexWhere((p) => p.id == paymentIdStr);
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
    final paymentIdStr = paymentId?.toString() ?? '';
    try {
      return _payments.firstWhere((p) => p.id == paymentIdStr);
    } catch (e) {
      return null;
    }
  }

  // ========== GET PAYMENTS BY APPOINTMENT ==========

  Future<List<Payment>> getPaymentsByAppointment(dynamic appointmentId) async {
    try {
      final appointmentIdStr = appointmentId?.toString() ?? '';

      final paymentsData = await _supabaseService.getPaymentsByAppointment(
        appointmentIdStr,
      );

      return paymentsData.map((data) {
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
      final paymentIdStr = paymentId?.toString() ?? '';
      final payment = getPaymentById(paymentIdStr);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      if (!payment.isCompleted) {
        throw Exception('Can only refund completed payments');
      }

      final refundAmount = amount ?? payment.total;
      final refundTxnId =
          'refund_${payment.transactionId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create refund payment record in Supabase
      await _supabaseService.insertPayment({
        'appointment_id': payment.appointmentId,
        'user_id': payment.userId,
        'subtotal': -refundAmount,
        'tax': 0.0,
        'total': -refundAmount,
        'currency': payment.currency,
        'method': 'refund',
        'status': 'refunded',
        'transaction_id': refundTxnId,
        'invoice_number': 'REF-${payment.invoiceNumber}',
        'service_description': 'Refund for ${payment.serviceDescription}',
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Update original payment status if full refund
      if (amount == null || amount >= payment.total) {
        await _supabaseService.updatePayment(paymentIdStr, {
          'status': 'refunded',
        });

        final index = _payments.indexWhere((p) => p.id == paymentIdStr);
        if (index != -1) {
          _payments[index] = _payments[index].copyWith(status: 'refunded');
        }

        // Update appointment status to 'refunded'
        final appointmentProvider = AppointmentProvider();
        if (payment.appointmentId != null &&
            payment.appointmentId!.isNotEmpty) {
          final appointmentIdInt =
              int.tryParse(payment.appointmentId!) ??
              payment.appointmentId!.hashCode;
          await appointmentProvider.updateAppointmentStatus(
            appointmentIdInt,
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

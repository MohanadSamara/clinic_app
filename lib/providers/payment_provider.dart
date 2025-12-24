// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../db/db_helper.dart';
import '../models/payment.dart';
import '../models/appointment.dart';
import 'appointment_provider.dart';

class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  bool _isProcessing = false;
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _isLoading;

  // Load payments for a user
  Future<void> loadPayments(int userId) async {
    _isLoading = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      final paymentData = await DBHelper.instance.getPaymentsByUser(userId);
      _payments = paymentData.map((data) => Payment.fromMap(data)).toList();
      _payments.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      ); // Newest first
    } catch (e) {
      debugPrint('Error loading payments: $e');
      _payments = [];
    } finally {
      _isLoading = false;
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());
    }
  }

  // Create payment for appointment
  Future<Payment?> createPayment({
    required int appointmentId,
    required int userId,
    required double subtotal,
    required String serviceDescription,
    String currency = 'JOD',
  }) async {
    _isProcessing = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      // Calculate tax (16% VAT in Jordan)
      final tax = subtotal * 0.16;
      final total = subtotal + tax;

      final payment = Payment(
        appointmentId: appointmentId,
        userId: userId,
        subtotal: subtotal,
        tax: tax,
        total: total,
        currency: currency,
        method: 'pending', // Will be set during payment
        transactionId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: Payment.generateInvoiceNumber(),
        serviceDescription: serviceDescription,
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await DBHelper.instance.insertPayment(payment.toMap());
      final newPayment = payment.copyWith(id: id);

      _payments.insert(0, newPayment); // Add to top of list
      notifyListeners();

      return newPayment;
    } catch (e) {
      debugPrint('Error creating payment: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Process online payment (mock implementation)
  Future<bool> processOnlinePayment({
    required int paymentId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
  }) async {
    _isProcessing = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

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

      // Update payment in database
      await DBHelper.instance.updatePayment(paymentId, {
        'method': 'card',
        'status': 'completed',
        'transaction_id': transactionId,
        'payment_intent_id': paymentIntentId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Update local payment
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(
          method: 'card',
          status: 'completed',
          transactionId: transactionId,
          paymentIntentId: paymentIntentId,
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      // Check if appointment has been accepted by a doctor before allowing payment
      final appointmentData = await DBHelper.instance.getAppointmentById(
        _payments[index].appointmentId,
      );
      final appointment = appointmentData != null
          ? Appointment.fromMap(appointmentData)
          : null;

      if (appointment == null || appointment.doctorId == null) {
        throw Exception(
          'Cannot process payment: Appointment must be accepted by a doctor first',
        );
      }

      // Update appointment status to 'paid'
      final appointmentProvider = AppointmentProvider();
      await appointmentProvider.updateAppointmentStatus(
        _payments[index].appointmentId,
        'paid',
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing online payment: $e');

      // Update payment status to failed
      await DBHelper.instance.updatePayment(paymentId, {
        'status': 'failed',
        'completed_at': DateTime.now().toIso8601String(),
      });

      final index = _payments.indexWhere((p) => p.id == paymentId);
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
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());
    }
  }

  // Process cash payment
  Future<bool> processCashPayment(int paymentId) async {
    _isProcessing = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      final transactionId = 'cash_${DateTime.now().millisecondsSinceEpoch}';

      await DBHelper.instance.updatePayment(paymentId, {
        'method': 'cash',
        'status': 'completed',
        'transaction_id': transactionId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(
          method: 'cash',
          status: 'completed',
          transactionId: transactionId,
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      // Check if appointment has been accepted by a doctor before allowing payment
      final appointmentData = await DBHelper.instance.getAppointmentById(
        _payments[index].appointmentId,
      );
      final appointment = appointmentData != null
          ? Appointment.fromMap(appointmentData)
          : null;

      if (appointment == null || appointment.doctorId == null) {
        throw Exception(
          'Cannot process payment: Appointment must be accepted by a doctor first',
        );
      }

      // For cash payments, do not update appointment status here as it's called upon completion
      // Appointment status is already 'completed' when cash payment is processed

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing cash payment: $e');
      return false;
    } finally {
      _isProcessing = false;
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());
    }
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(int paymentId) async {
    try {
      final paymentData = await DBHelper.instance.getPaymentById(paymentId);
      return paymentData != null ? Payment.fromMap(paymentData) : null;
    } catch (e) {
      debugPrint('Error getting payment: $e');
      return null;
    }
  }

  // Get payments by appointment
  Future<List<Payment>> getPaymentsByAppointment(int appointmentId) async {
    try {
      final paymentData = await DBHelper.instance.getPaymentsByAppointment(
        appointmentId,
      );
      return paymentData.map((data) => Payment.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting payments by appointment: $e');
      return [];
    }
  }

  // Process refund
  Future<bool> processRefund({
    required int paymentId,
    double? amount,
    String? reason,
  }) async {
    _isProcessing = true;
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() => notifyListeners());

    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      if (!payment.isCompleted) {
        throw Exception('Can only refund completed payments');
      }

      final refundAmount = amount ?? payment.total;
      final refundTxnId =
          'refund_${payment.transactionId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create refund payment record
      final refundPayment = Payment(
        appointmentId: payment.appointmentId,
        userId: payment.userId,
        subtotal: -refundAmount,
        tax: 0.0, // No tax on refunds
        total: -refundAmount,
        currency: payment.currency,
        method: 'refund',
        status: 'refunded',
        transactionId: refundTxnId,
        invoiceNumber: 'REF-${payment.invoiceNumber}',
        serviceDescription: 'Refund for ${payment.serviceDescription}',
        createdAt: DateTime.now().toIso8601String(),
        completedAt: DateTime.now().toIso8601String(),
      );

      await DBHelper.instance.insertPayment(refundPayment.toMap());

      // Update original payment status if full refund
      if (amount == null || amount >= payment.total) {
        await DBHelper.instance.updatePayment(paymentId, {
          'status': 'refunded',
        });

        final index = _payments.indexWhere((p) => p.id == paymentId);
        if (index != -1) {
          _payments[index] = _payments[index].copyWith(status: 'refunded');
        }

        // Update appointment status to 'refunded'
        final appointmentProvider = AppointmentProvider();
        await appointmentProvider.updateAppointmentStatus(
          payment.appointmentId,
          'refunded',
        );
      }

      // Add audit notification
      await DBHelper.instance.insertNotification({
        'user_id': payment.userId,
        'title': 'Refund Processed',
        'message':
            'Refund of ${payment.currency} ${refundAmount.toStringAsFixed(2)} processed for ${payment.serviceDescription}',
        'type': 'payment',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
        'data': '{"payment_id": $paymentId, "refund_amount": $refundAmount}',
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      return false;
    } finally {
      _isProcessing = false;
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => notifyListeners());
    }
  }

  // Get payment statistics
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

  // Clear payments (for logout)
  void clearPayments() {
    _payments.clear();
    notifyListeners();
  }
}








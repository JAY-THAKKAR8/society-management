import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';

/// Unified utility class for late fee calculations and operations
class LateFeeCalculator {
  // Late fee amount per day
  static const double dailyLateFeeAmount = 10.0;

  /// Calculate late fee for given days
  static double calculateLateFee(int daysLate) {
    if (daysLate <= 0) return 0.0;
    return daysLate * dailyLateFeeAmount;
  }

  /// Calculate and apply late fees for all active periods
  static Future<int> calculateAndApplyLateFees() async {
    try {
      int updatedCount = 0;

      // Get active maintenance periods
      final periodsSnapshot =
          await FirebaseFirestore.instance.collection('maintenance_periods').where('is_active', isEqualTo: true).get();

      if (periodsSnapshot.docs.isEmpty) return 0;

      final now = DateTime.now();

      // Process each period
      for (final doc in periodsSnapshot.docs) {
        final periodData = doc.data();
        final periodId = doc.id;
        final dueDateStr = periodData['due_date'] as String?;

        if (dueDateStr == null) continue;

        // Check if due date has passed
        final dueDate = DateTime.parse(dueDateStr);

        if (now.isAfter(dueDate)) {
          final daysLate = now.difference(dueDate).inDays;
          if (daysLate <= 0) continue;

          // Get all payments for this period
          final paymentsSnapshot = await FirebaseFirestore.instance
              .collection('maintenance_payments')
              .where('period_id', isEqualTo: periodId)
              .get();

          if (paymentsSnapshot.docs.isEmpty) continue;

          // Filter for pending payments
          final pendingPayments = paymentsSnapshot.docs
              .map((doc) => MaintenancePaymentModel.fromJson(doc.data()))
              .where(
                  (payment) => payment.status == PaymentStatus.pending || payment.status == PaymentStatus.partiallyPaid)
              .toList();

          // Update each payment with late fee
          for (final payment in pendingPayments) {
            if (payment.id == null) continue;

            // Calculate late fee
            final lateFeeAmount = calculateLateFee(daysLate);

            // Update payment with late fee
            final success = await _updatePaymentWithLateFee(
              payment: payment,
              daysLate: daysLate,
              lateFeeAmount: lateFeeAmount,
            );

            if (success) {
              updatedCount++;
            }
          }
        }
      }

      return updatedCount;
    } catch (e) {
      debugPrint('Error calculating late fees: $e');
      return 0;
    }
  }

  /// Update a payment with late fee
  static Future<bool> _updatePaymentWithLateFee({
    required MaintenancePaymentModel payment,
    required int daysLate,
    required double lateFeeAmount,
  }) async {
    try {
      if (payment.id == null) {
        return false;
      }

      // Get the payment document reference
      final paymentRef = FirebaseFirestore.instance.collection('maintenance_payments').doc(payment.id);

      // Update the payment with late fee
      final now = Timestamp.now();
      await paymentRef.update({
        'late_fee_amount': lateFeeAmount,
        'days_late': daysLate,
        'has_late_fee': true,
        'status': 'overdue',
        'updated_at': now,
      });

      // Create a late fee record
      final lateFeeRef = FirebaseFirestore.instance.collection('late_fees').doc();
      await lateFeeRef.set({
        'id': lateFeeRef.id,
        'payment_id': payment.id,
        'period_id': payment.periodId,
        'user_id': payment.userId,
        'user_name': payment.userName,
        'amount': lateFeeAmount,
        'days_late': daysLate,
        'applied_date': now,
        'is_paid': false,
        'paid_date': null,
        'created_at': now,
        'updated_at': now,
      });

      // Log activity
      final activityRef = FirebaseFirestore.instance.collection('activities').doc();
      await activityRef.set({
        'id': activityRef.id,
        'message': '⚠️ Late fee of ₹$lateFeeAmount applied to ${payment.userName} for $daysLate days late',
        'type': 'late_fee',
        'timestamp': now,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating payment with late fee: $e');
      return false;
    }
  }

  /// Record a late fee payment
  static Future<bool> recordLateFeePayment({
    required String userId,
    required String userName,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? receiptNumber,
  }) async {
    try {
      if (amount <= 0) {
        return false; // No payment to record
      }

      final now = Timestamp.now();

      // Get all unpaid late fees for this user
      final lateFeeSnapshot = await FirebaseFirestore.instance
          .collection('late_fees')
          .where('user_id', isEqualTo: userId)
          .where('is_paid', isEqualTo: false)
          .orderBy('created_at', descending: false) // Pay oldest first
          .get();

      if (lateFeeSnapshot.docs.isEmpty) {
        return false; // No unpaid late fees
      }

      double remainingAmount = amount;
      int paidCount = 0;

      // Pay off late fees one by one, starting with the oldest
      for (final doc in lateFeeSnapshot.docs) {
        if (remainingAmount <= 0) break;

        final lateFeeRef = doc.reference;
        final lateFeeAmount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;

        if (lateFeeAmount <= 0) continue;

        // Determine how much to pay for this late fee
        final paymentAmount = remainingAmount >= lateFeeAmount ? lateFeeAmount : remainingAmount;
        remainingAmount -= paymentAmount;

        // Update the late fee record
        await lateFeeRef.update({
          'is_paid': paymentAmount >= lateFeeAmount,
          'paid_amount': paymentAmount,
          'paid_date': now,
          'payment_method': paymentMethod,
          'receipt_number': receiptNumber,
          'updated_at': now,
        });

        paidCount++;
      }

      if (paidCount > 0) {
        // Log activity
        final activityRef = FirebaseFirestore.instance.collection('activities').doc();
        await activityRef.set({
          'id': activityRef.id,
          'message': '💰 Late fee of ₹${amount.toStringAsFixed(2)} paid by $userName',
          'type': 'late_fee_payment',
          'timestamp': now,
        });

        // Update society income
        final societyRef = FirebaseFirestore.instance.collection('society_info').doc('income');
        final societyDoc = await societyRef.get();

        if (societyDoc.exists) {
          final currentLateFeeIncome = (societyDoc.data()?['late_fee_income'] as num?)?.toDouble() ?? 0.0;
          await societyRef.update({
            'late_fee_income': currentLateFeeIncome + amount,
            'updated_at': now,
          });
        } else {
          await societyRef.set({
            'late_fee_income': amount,
            'created_at': now,
            'updated_at': now,
          });
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error recording late fee payment: $e');
      return false;
    }
  }
}

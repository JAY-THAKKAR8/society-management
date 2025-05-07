import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A utility class for calculating and managing late fees
class LateFeeCalculator {
  /// Calculate late fee based on days late and amount
  /// Default rate is 10 Rs per day
  static double calculateLateFee({
    required int daysLate,
    double ratePerDay = 10.0,
  }) {
    if (daysLate <= 0) return 0.0;
    return daysLate * ratePerDay;
  }

  /// Calculate days late based on due date and current date
  static int calculateDaysLate({
    required DateTime dueDate,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    if (now.isBefore(dueDate)) return 0;
    
    return now.difference(dueDate).inDays;
  }

  /// Record a late fee payment
  static Future<void> recordLateFeePayment({
    required String userId,
    required String userName,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? receiptNumber,
  }) async {
    try {
      final now = Timestamp.now();
      
      // Create a record in the late_fee_payments collection
      await FirebaseFirestore.instance.collection('late_fee_payments').add({
        'user_id': userId,
        'user_name': userName,
        'amount': amount,
        'payment_date': Timestamp.fromDate(paymentDate),
        'payment_method': paymentMethod,
        'receipt_number': receiptNumber,
        'created_at': now,
        'updated_at': now,
      });
      
      // Update the total late fees collected in the stats collection
      final statsRef = FirebaseFirestore.instance.collection('maintenance_stats').doc('late_fees');
      final statsDoc = await statsRef.get();
      
      if (statsDoc.exists) {
        // Update existing stats
        final currentTotal = (statsDoc.data()?['total_collected'] as num?)?.toDouble() ?? 0.0;
        await statsRef.update({
          'total_collected': currentTotal + amount,
          'updated_at': now,
        });
      } else {
        // Create new stats document
        await statsRef.set({
          'total_collected': amount,
          'created_at': now,
          'updated_at': now,
        });
      }
    } catch (e) {
      debugPrint('Error recording late fee payment: $e');
      rethrow;
    }
  }
}

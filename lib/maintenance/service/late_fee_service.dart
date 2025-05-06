import 'package:flutter/foundation.dart';
import 'package:society_management/maintenance/service/late_fee_calculator.dart';

/// This class is deprecated. Use LateFeeCalculator instead.
@Deprecated('Use LateFeeCalculator instead')
class LateFeeService {
  // Late fee amount per day
  static const double dailyLateFeeAmount = LateFeeCalculator.dailyLateFeeAmount;

  /// Calculate late fees for all active periods
  Future<int> calculateLateFees() async {
    debugPrint('LateFeeService is deprecated. Use LateFeeCalculator.calculateAndApplyLateFees() instead.');
    return await LateFeeCalculator.calculateAndApplyLateFees();
  }

  /// Record a late fee payment
  Future<bool> recordLateFeePayment({
    required String userId,
    required String userName,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? receiptNumber,
  }) async {
    debugPrint('LateFeeService is deprecated. Use LateFeeCalculator.recordLateFeePayment() instead.');
    return await LateFeeCalculator.recordLateFeePayment(
      userId: userId,
      userName: userName,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      receiptNumber: receiptNumber,
    );
  }
}

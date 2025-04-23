import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IMaintenanceRepository {
  final FirebaseFirestore firestore;
  IMaintenanceRepository(this.firestore);

  /// Create a new maintenance period
  FirebaseResult<MaintenancePeriodModel> createMaintenancePeriod({
    required String name,
    required String description,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime dueDate,
  });

  /// Get all maintenance periods
  FirebaseResult<List<MaintenancePeriodModel>> getAllMaintenancePeriods();

  /// Get active maintenance periods
  FirebaseResult<List<MaintenancePeriodModel>> getActiveMaintenancePeriods();

  /// Get a specific maintenance period
  FirebaseResult<MaintenancePeriodModel> getMaintenancePeriod({
    required String periodId,
  });

  /// Update a maintenance period
  FirebaseResult<MaintenancePeriodModel> updateMaintenancePeriod({
    required String periodId,
    String? name,
    String? description,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    bool? isActive,
  });

  /// Delete a maintenance period
  FirebaseResult<void> deleteMaintenancePeriod({
    required String periodId,
  });

  /// Record a maintenance payment
  FirebaseResult<MaintenancePaymentModel> recordPayment({
    required String periodId,
    required String userId,
    required String userName,
    required String userVillaNumber,
    required String userLineNumber,
    required String collectedBy,
    required String collectorName,
    required double amount,
    required double amountPaid,
    required DateTime paymentDate,
    required String paymentMethod,
    PaymentStatus status,
    String? notes,
    String? receiptNumber,
  });

  /// Get all payments for a period
  FirebaseResult<List<MaintenancePaymentModel>> getPaymentsForPeriod({
    required String periodId,
  });

  /// Get payments for a specific user
  FirebaseResult<List<MaintenancePaymentModel>> getPaymentsForUser({
    required String userId,
  });

  /// Get payments for a specific line
  FirebaseResult<List<MaintenancePaymentModel>> getPaymentsForLine({
    required String periodId,
    required String lineNumber,
  });

  /// Get payment statistics for a period
  FirebaseResult<Map<String, dynamic>> getPaymentStatistics({
    required String periodId,
  });

  /// Update payment status
  FirebaseResult<MaintenancePaymentModel> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    double? amountPaid,
    String? notes,
  });
}

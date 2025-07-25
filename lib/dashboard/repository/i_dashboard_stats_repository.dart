import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IDashboardStatsRepository {
  final FirebaseFirestore firestore;
  IDashboardStatsRepository(this.firestore);

  /// Get admin dashboard stats
  FirebaseResult<DashboardStatsModel> getDashboardStats();

  /// Get line head dashboard stats for a specific line
  FirebaseResult<DashboardStatsModel> getLineStats(String lineNumber);

  /// Get user dashboard stats for a specific line
  FirebaseResult<DashboardStatsModel> getUserStats(String lineNumber);

  /// Increment total members count
  FirebaseResult<void> incrementTotalMembers();

  /// Increment total expenses amount (when adding new expense)
  FirebaseResult<void> incrementTotalExpenses(double amount);

  /// Update expense amount (when editing existing expense)
  FirebaseResult<void> updateExpenseAmount({
    required double oldAmount,
    required double newAmount,
  });

  /// Decrement total expenses amount (when deleting expense)
  FirebaseResult<void> decrementTotalExpenses(double amount);

  /// Update dashboard stats when maintenance payment is recorded
  Future<void> updateDashboardsForMaintenancePayment({
    required String lineNumber,
    required double amountPaid,
    required double amountPending,
    bool isFullyPaid = false,
    String? userId,
  });

  /// Update dashboard stats when a maintenance period is created
  Future<void> updateDashboardsForMaintenancePeriodCreation();

  /// Update stats for a specific line
  Future<void> updateLineStats(String lineNumber);

  /// Update admin dashboard stats
  Future<void> updateAdminDashboardStats();
}

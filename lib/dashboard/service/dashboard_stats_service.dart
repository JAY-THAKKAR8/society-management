import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/extentions/firestore_extentions.dart';

/// Simple, clean dashboard stats service
/// Handles all dashboard statistics updates in one place
class DashboardStatsService {
  static final DashboardStatsService _instance = DashboardStatsService._internal();
  factory DashboardStatsService() => _instance;
  DashboardStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // EXPENSE OPERATIONS (Simple & Clean)
  // ========================================

  /// Add expense amount to all dashboards
  Future<void> addExpense(double amount) async {
    try {
      await _updateAllDashboards((current) => current + amount);
      print('✅ Added ₹$amount to all dashboards');
    } catch (e) {
      print('❌ Error adding expense: $e');
      rethrow;
    }
  }

  /// Remove expense amount from all dashboards
  Future<void> removeExpense(double amount) async {
    try {
      await _updateAllDashboards((current) => current - amount);
      print('✅ Removed ₹$amount from all dashboards');
    } catch (e) {
      print('❌ Error removing expense: $e');
      rethrow;
    }
  }

  /// Update expense amount (when editing)
  Future<void> updateExpense({
    required double oldAmount,
    required double newAmount,
  }) async {
    try {
      final difference = newAmount - oldAmount;
      await _updateAllDashboards((current) => current + difference);
      print('✅ Updated expense: ₹$oldAmount → ₹$newAmount (diff: ₹$difference)');
    } catch (e) {
      print('❌ Error updating expense: $e');
      rethrow;
    }
  }

  // ========================================
  // USER OPERATIONS (Simple & Clean)
  // ========================================

  /// Add new user to dashboards
  Future<void> addUser() async {
    try {
      await _updateAllDashboards(
        (current) => current, // Don't change expenses
        memberCountChange: 1,
      );
      print('✅ Added new user to dashboards');
    } catch (e) {
      print('❌ Error adding user: $e');
      rethrow;
    }
  }

  /// Remove user from dashboards
  Future<void> removeUser() async {
    try {
      await _updateAllDashboards(
        (current) => current, // Don't change expenses
        memberCountChange: -1,
      );
      print('✅ Removed user from dashboards');
    } catch (e) {
      print('❌ Error removing user: $e');
      rethrow;
    }
  }

  // ========================================
  // MAINTENANCE OPERATIONS (Simple & Clean)
  // ========================================

  /// Update maintenance stats
  Future<void> updateMaintenance({
    double? collectedChange,
    double? pendingChange,
    int? fullyPaidChange,
  }) async {
    try {
      await _updateMaintenanceStats(
        collectedChange: collectedChange,
        pendingChange: pendingChange,
        fullyPaidChange: fullyPaidChange,
      );
      print('✅ Updated maintenance stats');
    } catch (e) {
      print('❌ Error updating maintenance: $e');
      rethrow;
    }
  }

  // ========================================
  // PRIVATE HELPER METHODS (Clean & Simple)
  // ========================================

  /// Update all dashboard collections with expense changes
  Future<void> _updateAllDashboards(
    double Function(double current) expenseCalculator, {
    int memberCountChange = 0,
  }) async {
    final now = Timestamp.now();
    final batch = _firestore.batch();

    // Update admin dashboard
    await _updateAdminDashboard(batch, expenseCalculator, memberCountChange, now);

    // Update line head dashboards
    await _updateLineHeadDashboards(batch, expenseCalculator, memberCountChange, now);

    // Update user dashboards
    await _updateUserDashboards(batch, expenseCalculator, memberCountChange, now);

    // Commit all changes at once
    await batch.commit();
  }

  /// Update admin dashboard stats
  Future<void> _updateAdminDashboard(
    WriteBatch batch,
    double Function(double) expenseCalculator,
    int memberCountChange,
    Timestamp now,
  ) async {
    final adminRef = _firestore.adminDashboardStats.doc('stats');
    final adminDoc = await adminRef.get();

    if (adminDoc.exists) {
      final data = adminDoc.data() as Map<String, dynamic>;
      final currentExpenses = (data['total_expenses'] as num?)?.toDouble() ?? 0.0;
      final currentMembers = (data['total_members'] as num?)?.toInt() ?? 0;

      batch.update(adminRef, {
        'total_expenses': expenseCalculator(currentExpenses),
        'total_members': currentMembers + memberCountChange,
        'updated_at': now,
      });
    } else {
      // Create new admin stats
      batch.set(adminRef, {
        'total_expenses': expenseCalculator(0.0),
        'total_members': memberCountChange > 0 ? memberCountChange : 0,
        'maintenance_collected': 0.0,
        'maintenance_pending': 0.0,
        'active_maintenance': 0,
        'fully_paid': 0,
        'updated_at': now,
      });
    }
  }

  /// Update line head dashboard stats
  Future<void> _updateLineHeadDashboards(
    WriteBatch batch,
    double Function(double) expenseCalculator,
    int memberCountChange,
    Timestamp now,
  ) async {
    final lineHeadDocs = await _firestore.lineHeadDashboardStats.get();

    for (final doc in lineHeadDocs.docs) {
      final data = doc.data();
      final currentExpenses = (data['total_expenses'] as num?)?.toDouble() ?? 0.0;
      final currentMembers = (data['total_members'] as num?)?.toInt() ?? 0;

      batch.update(doc.reference, {
        'total_expenses': expenseCalculator(currentExpenses),
        'total_members': currentMembers + memberCountChange,
        'updated_at': now,
      });
    }
  }

  /// Update user dashboard stats
  Future<void> _updateUserDashboards(
    WriteBatch batch,
    double Function(double) expenseCalculator,
    int memberCountChange,
    Timestamp now,
  ) async {
    final userDocs = await _firestore.userSpecificStats.get();

    for (final doc in userDocs.docs) {
      final data = doc.data();
      final currentExpenses = (data['total_expenses'] as num?)?.toDouble() ?? 0.0;

      batch.update(doc.reference, {
        'total_expenses': expenseCalculator(currentExpenses),
        'updated_at': now,
      });
    }
  }

  /// Update maintenance stats in all dashboards
  Future<void> _updateMaintenanceStats({
    double? collectedChange,
    double? pendingChange,
    int? fullyPaidChange,
  }) async {
    final now = Timestamp.now();
    final batch = _firestore.batch();

    // Update admin dashboard maintenance stats
    final adminRef = _firestore.adminDashboardStats.doc('stats');
    final adminDoc = await adminRef.get();

    if (adminDoc.exists) {
      final data = adminDoc.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{'updated_at': now};

      if (collectedChange != null) {
        final current = (data['maintenance_collected'] as num?)?.toDouble() ?? 0.0;
        updates['maintenance_collected'] = current + collectedChange;
      }

      if (pendingChange != null) {
        final current = (data['maintenance_pending'] as num?)?.toDouble() ?? 0.0;
        updates['maintenance_pending'] = current + pendingChange;
      }

      if (fullyPaidChange != null) {
        final current = (data['fully_paid'] as num?)?.toInt() ?? 0;
        updates['fully_paid'] = current + fullyPaidChange;
      }

      batch.update(adminRef, updates);
    }

    await batch.commit();
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Recalculate all stats from scratch (use sparingly)
  Future<void> recalculateAllStats() async {
    try {
      // This would recalculate everything from the database
      // Implementation depends on your specific needs
      print('🔄 Recalculating all dashboard stats...');

      // Calculate total expenses from expenses collection
      final expensesSnapshot = await _firestore.collection('expenses').get();
      double totalExpenses = 0.0;

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpenses += amount;
      }

      // Update all dashboards with calculated total
      await _updateAllDashboards((_) => totalExpenses);

      print('✅ Recalculation complete. Total expenses: ₹$totalExpenses');
    } catch (e) {
      print('❌ Error recalculating stats: $e');
      rethrow;
    }
  }
}

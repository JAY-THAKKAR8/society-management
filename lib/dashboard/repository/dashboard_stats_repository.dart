import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@Injectable(as: IDashboardStatsRepository)
class DashboardStatsRepository extends IDashboardStatsRepository {
  DashboardStatsRepository(super.firestore);

  // Collection references for different dashboard types
  final CollectionReference _adminDashboardCollection = FirebaseFirestore.instance.collection('admin_dashboard_stats');

  final CollectionReference _lineHeadDashboardCollection =
      FirebaseFirestore.instance.collection('line_head_dashboard_stats');

  final CollectionReference _userDashboardCollection = FirebaseFirestore.instance.collection('user_dashboard_stats');

  @override
  FirebaseResult<DashboardStatsModel> getDashboardStats() {
    return Result<DashboardStatsModel>().tryCatch(
      run: () async {
        // Get or create admin dashboard stats
        final statsDoc = await _adminDashboardCollection.doc('stats').get();
        final now = Timestamp.now();

        // If stats don't exist, calculate and create them
        if (!statsDoc.exists) {
          final stats = await _calculateAdminDashboardStats();

          // Create initial stats document
          await _adminDashboardCollection.doc('stats').set({
            'total_members': stats.totalMembers,
            'total_expenses': stats.totalExpenses,
            'maintenance_collected': stats.maintenanceCollected,
            'maintenance_pending': stats.maintenancePending,
            'active_maintenance': stats.activeMaintenance,
            'updated_at': now,
          });

          return stats;
        }

        // Update the stats with fresh calculations
        final updatedStats = await _calculateAdminDashboardStats();

        // Update the stats document
        await _adminDashboardCollection.doc('stats').update({
          'total_members': updatedStats.totalMembers,
          'total_expenses': updatedStats.totalExpenses,
          'maintenance_collected': updatedStats.maintenanceCollected,
          'maintenance_pending': updatedStats.maintenancePending,
          'active_maintenance': updatedStats.activeMaintenance,
          'updated_at': now,
        });

        // Get the updated document
        final updatedStatsDoc = await _adminDashboardCollection.doc('stats').get();
        return DashboardStatsModel.fromJson(updatedStatsDoc.data() as Map<String, dynamic>);
      },
    );
  }

  // Helper method to calculate admin dashboard stats
  Future<DashboardStatsModel> _calculateAdminDashboardStats() async {
    final now = Timestamp.now();

    // Get maintenance stats
    double maintenanceCollected = 0.0;
    double maintenancePending = 0.0;
    int activeMaintenance = 0;

    // Count total members (excluding admins)
    final usersSnapshot = await FirebaseFirestore.instance.users.get();
    final totalMembers = usersSnapshot.docs.where((doc) {
      final role = doc.data()['role'] as String?;
      return role != 'admin' && role != 'ADMIN' && role != AppConstants.admins;
    }).length;

    // Count active maintenance periods
    final maintenanceSnapshot = await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();

    activeMaintenance = maintenanceSnapshot.docs.length;

    // Sum up maintenance amounts
    for (final doc in maintenanceSnapshot.docs) {
      maintenanceCollected += (doc.data()['total_collected'] as num?)?.toDouble() ?? 0.0;
      maintenancePending += (doc.data()['total_pending'] as num?)?.toDouble() ?? 0.0;
    }

    // Get total expenses
    final expensesSnapshot = await FirebaseFirestore.instance.collection('expenses').get();
    double totalExpenses = 0.0;

    for (final doc in expensesSnapshot.docs) {
      totalExpenses += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return DashboardStatsModel(
      totalMembers: totalMembers,
      totalExpenses: totalExpenses,
      maintenanceCollected: maintenanceCollected,
      maintenancePending: maintenancePending,
      activeMaintenance: activeMaintenance,
      updatedAt: now.toDate().toString(),
    );
  }

  @override
  FirebaseResult<void> incrementTotalMembers() {
    return Result<void>().tryCatch(
      run: () async {
        // Update all dashboard collections
        await _updateAllDashboardsForMemberChange(1);
        return;
      },
    );
  }

  // Helper method to update all dashboard collections when member count changes
  Future<void> _updateAllDashboardsForMemberChange(int change) async {
    final now = Timestamp.now();
    final batch = FirebaseFirestore.instance.batch();

    // Update admin dashboard
    final adminStatsRef = _adminDashboardCollection.doc('stats');
    final adminStatsDoc = await adminStatsRef.get();

    if (adminStatsDoc.exists) {
      final data = adminStatsDoc.data() as Map<String, dynamic>?;
      final currentCount = data?['total_members'] as int? ?? 0;
      batch.update(adminStatsRef, {
        'total_members': currentCount + change,
        'updated_at': now,
      });
    } else {
      batch.set(adminStatsRef, {
        'total_members': change > 0 ? change : 0,
        'total_expenses': 0.0,
        'maintenance_collected': 0.0,
        'maintenance_pending': 0.0,
        'active_maintenance': 0,
        'updated_at': now,
      });
    }

    // Commit the batch
    await batch.commit();

    // After batch commit, recalculate line-specific stats
    await _updateAllLineStats();
  }

  // Helper method to update all line stats
  Future<void> _updateAllLineStats() async {
    // Get all lines
    final usersSnapshot = await FirebaseFirestore.instance.users.get();
    final lineNumbers = usersSnapshot.docs
        .map((doc) => doc.data()['line_number'] as String?)
        .where((line) => line != null)
        .toSet()
        .cast<String>();

    // Update stats for each line
    for (final lineNumber in lineNumbers) {
      await updateLineStats(lineNumber);
    }
  }

  // Public method to update stats for a specific line
  @override
  Future<void> updateLineStats(String lineNumber) async {
    final lineStats = await _calculateLineStats(lineNumber);
    final now = Timestamp.now();

    // Update line head dashboard
    await _lineHeadDashboardCollection.doc(lineNumber).set({
      'total_members': lineStats.totalMembers,
      'total_expenses': lineStats.totalExpenses,
      'maintenance_collected': lineStats.maintenanceCollected,
      'maintenance_pending': lineStats.maintenancePending,
      'active_maintenance': lineStats.activeMaintenance,
      'line_number': lineNumber,
      'updated_at': now,
    });

    // Update user dashboard for this line
    await _userDashboardCollection.doc(lineNumber).set({
      'total_members': lineStats.totalMembers,
      'maintenance_collected': lineStats.maintenanceCollected,
      'maintenance_pending': lineStats.maintenancePending,
      'active_maintenance': lineStats.activeMaintenance,
      'line_number': lineNumber,
      'updated_at': now,
    });
  }

  @override
  FirebaseResult<DashboardStatsModel> getLineStats(String lineNumber) {
    return Result<DashboardStatsModel>().tryCatch(
      run: () async {
        // Check if we have cached stats for this line
        final lineStatsDoc = await _lineHeadDashboardCollection.doc(lineNumber).get();

        if (lineStatsDoc.exists) {
          // Update stats in the background but return cached stats immediately
          updateLineStats(lineNumber); // Don't await this
          return DashboardStatsModel.fromJson(lineStatsDoc.data() as Map<String, dynamic>);
        }

        // If no cached stats, calculate them
        final stats = await _calculateLineStats(lineNumber);

        // Cache the stats for future use
        await updateLineStats(lineNumber);

        return stats;
      },
    );
  }

  // Helper method to calculate line stats
  Future<DashboardStatsModel> _calculateLineStats(String lineNumber) async {
    final now = Timestamp.now();

    // Count members in this line (excluding admins)
    final usersSnapshot = await FirebaseFirestore.instance.users.get();
    final lineUsers = usersSnapshot.docs.where((doc) {
      final role = doc.data()['role'] as String?;
      final userLineNumber = doc.data()['line_number'] as String?;
      return userLineNumber == lineNumber && role != 'admin' && role != 'ADMIN' && role != AppConstants.admins;
    }).toList();
    final totalMembers = lineUsers.length;

    // Get maintenance stats for this line
    double maintenanceCollected = 0.0;
    double maintenancePending = 0.0;
    int activeMaintenance = 0;

    // Count active maintenance periods
    final maintenanceSnapshot = await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();

    activeMaintenance = maintenanceSnapshot.docs.length;

    // For each active period, get payments for this line
    for (final periodDoc in maintenanceSnapshot.docs) {
      final periodId = periodDoc.id;
      final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
          .where('period_id', isEqualTo: periodId)
          .where('user_line_number', isEqualTo: lineNumber)
          .get();

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final userRole =
            paymentData['user_id'] == 'admin' || (paymentData['user_name'] as String?)?.toLowerCase() == 'admin';

        // Skip admin users
        if (userRole) continue;

        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0.0;

        maintenanceCollected += amountPaid;
        maintenancePending += (amount - amountPaid);
      }
    }

    // Get line-specific expenses
    final expensesSnapshot =
        await FirebaseFirestore.instance.collection('expenses').where('line_number', isEqualTo: lineNumber).get();

    double totalExpenses = 0.0;
    for (final doc in expensesSnapshot.docs) {
      totalExpenses += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return DashboardStatsModel(
      totalMembers: totalMembers,
      totalExpenses: totalExpenses,
      maintenanceCollected: maintenanceCollected,
      maintenancePending: maintenancePending,
      activeMaintenance: activeMaintenance,
      updatedAt: now.toDate().toString(),
    );
  }

  @override
  FirebaseResult<void> incrementTotalExpenses(double amount) {
    return Result<void>().tryCatch(
      run: () async {
        // Update all dashboard collections
        await _updateAllDashboardsForExpenseChange(amount);
        return;
      },
    );
  }

  // Helper method to update all dashboard collections when expense amount changes
  Future<void> _updateAllDashboardsForExpenseChange(double amount) async {
    final now = Timestamp.now();

    // Update admin dashboard
    final adminStatsRef = _adminDashboardCollection.doc('stats');
    final adminStatsDoc = await adminStatsRef.get();

    if (adminStatsDoc.exists) {
      final data = adminStatsDoc.data() as Map<String, dynamic>?;
      final currentAmount = data?['total_expenses'] as double? ?? 0.0;
      await adminStatsRef.update({
        'total_expenses': currentAmount + amount,
        'updated_at': now,
      });
    } else {
      await adminStatsRef.set({
        'total_members': 0,
        'total_expenses': amount,
        'maintenance_collected': 0.0,
        'maintenance_pending': 0.0,
        'active_maintenance': 0,
        'updated_at': now,
      });
    }
  }

  // New method to update dashboard stats when maintenance is recorded
  @override
  Future<void> updateDashboardsForMaintenancePayment({
    required String lineNumber,
    required double amountPaid,
    required double amountPending,
  }) async {
    final now = Timestamp.now();
    final batch = FirebaseFirestore.instance.batch();

    // Update admin dashboard
    final adminStatsRef = _adminDashboardCollection.doc('stats');
    final adminStatsDoc = await adminStatsRef.get();

    if (adminStatsDoc.exists) {
      final data = adminStatsDoc.data() as Map<String, dynamic>?;
      final currentCollected = data?['maintenance_collected'] as double? ?? 0.0;
      final currentPending = data?['maintenance_pending'] as double? ?? 0.0;

      batch.update(adminStatsRef, {
        'maintenance_collected': currentCollected + amountPaid,
        'maintenance_pending': currentPending - amountPaid + amountPending,
        'updated_at': now,
      });
    }

    // Update line head dashboard
    final lineHeadStatsRef = _lineHeadDashboardCollection.doc(lineNumber);
    final lineHeadStatsDoc = await lineHeadStatsRef.get();

    if (lineHeadStatsDoc.exists) {
      final data = lineHeadStatsDoc.data() as Map<String, dynamic>?;
      final currentCollected = data?['maintenance_collected'] as double? ?? 0.0;
      final currentPending = data?['maintenance_pending'] as double? ?? 0.0;

      batch.update(lineHeadStatsRef, {
        'maintenance_collected': currentCollected + amountPaid,
        'maintenance_pending': currentPending - amountPaid + amountPending,
        'updated_at': now,
      });
    }

    // Update user dashboard
    final userStatsRef = _userDashboardCollection.doc(lineNumber);
    final userStatsDoc = await userStatsRef.get();

    if (userStatsDoc.exists) {
      final data = userStatsDoc.data() as Map<String, dynamic>?;
      final currentCollected = data?['maintenance_collected'] as double? ?? 0.0;
      final currentPending = data?['maintenance_pending'] as double? ?? 0.0;

      batch.update(userStatsRef, {
        'maintenance_collected': currentCollected + amountPaid,
        'maintenance_pending': currentPending - amountPaid + amountPending,
        'updated_at': now,
      });
    }

    // Commit the batch
    await batch.commit();
  }

  // New method to update dashboard stats when a maintenance period is created
  @override
  Future<void> updateDashboardsForMaintenancePeriodCreation() async {
    // Recalculate all stats
    await updateAdminDashboardStats();
    await _updateAllLineStats();
  }

  // Method to update admin dashboard stats
  @override
  Future<void> updateAdminDashboardStats() async {
    try {
      final stats = await _calculateAdminDashboardStats();
      final now = Timestamp.now();

      // Update the stats document
      await _adminDashboardCollection.doc('stats').set({
        'total_members': stats.totalMembers,
        'total_expenses': stats.totalExpenses,
        'maintenance_collected': stats.maintenanceCollected,
        'maintenance_pending': stats.maintenancePending,
        'active_maintenance': stats.activeMaintenance,
        'updated_at': now,
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't fail the update
      debugPrint('Error updating admin dashboard stats: $e');
    }
  }

  // New method to get user dashboard stats
  @override
  FirebaseResult<DashboardStatsModel> getUserStats(String lineNumber) {
    return Result<DashboardStatsModel>().tryCatch(
      run: () async {
        // Check if we have cached stats for this line
        final userStatsDoc = await _userDashboardCollection.doc(lineNumber).get();

        if (userStatsDoc.exists) {
          // Update stats in the background but return cached stats immediately
          updateLineStats(lineNumber); // Don't await this
          return DashboardStatsModel.fromJson(userStatsDoc.data() as Map<String, dynamic>);
        }

        // If no cached stats, calculate them
        final stats = await _calculateLineStats(lineNumber);

        // Cache the stats for future use
        await updateLineStats(lineNumber);

        return stats;
      },
    );
  }
}

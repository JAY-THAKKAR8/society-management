import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          print('Created new admin dashboard stats:1111 ${stats.totalExpenses}');

          // Create initial stats document
          await _adminDashboardCollection.doc('stats').set({
            'total_members': stats.totalMembers,
            'total_expenses': stats.totalExpenses,
            'maintenance_collected': stats.maintenanceCollected,
            'maintenance_pending': stats.maintenancePending,
            'active_maintenance': stats.activeMaintenance,
            'fully_paid': stats.fullyPaidUsers,
            'updated_at': now,
          });

          print('Created new admin dashboard stats:2222 ${stats.totalExpenses}');

          return stats;
        }

        // Update the stats with fresh calculations
        final updatedStats = await _calculateAdminDashboardStats();
        print('Created new admin dashboard stats:3333 ${updatedStats.totalExpenses}');

        // Update the stats document
        await _adminDashboardCollection.doc('stats').update({
          'total_members': updatedStats.totalMembers,
          'total_expenses': updatedStats.totalExpenses,
          'maintenance_collected': updatedStats.maintenanceCollected,
          'maintenance_pending': updatedStats.maintenancePending,
          'active_maintenance': updatedStats.activeMaintenance,
          'fully_paid': updatedStats.fullyPaidUsers,
          'updated_at': now,
        });
        print('Created new admin dashboard stats:4444 ${updatedStats.totalExpenses}');

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
    int fullyPaidUsers = 0;

    // Count total members (excluding admins)
    final usersSnapshot = await FirebaseFirestore.instance.users.get();
    final totalMembers = usersSnapshot.docs.where((doc) {
      final role = doc.data()['role'] as String?;
      return role != 'admin' && role != 'ADMIN' && role != AppConstants.admins;
    }).length;

    // Count active maintenance periods
    final maintenanceSnapshot = await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();

    activeMaintenance = maintenanceSnapshot.docs.length;

    // Sum up maintenance amounts and count fully paid users
    if (maintenanceSnapshot.docs.isNotEmpty) {
      // Get the most recent period for fully paid count
      final latestPeriod = maintenanceSnapshot.docs.first;
      final periodId = latestPeriod.id;
      final paymentsSnapshot =
          await FirebaseFirestore.instance.maintenancePayments.where('period_id', isEqualTo: periodId).get();

      // Count fully paid users in the latest period
      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final userRole =
            paymentData['user_id'] == 'admin' || (paymentData['user_name'] as String?)?.toLowerCase() == 'admin';

        // Skip admin users
        if (userRole) continue;

        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0.0;

        // Count fully paid users
        if (amountPaid >= amount && amount > 0) {
          fullyPaidUsers++;
        }
      }
    }

    // Sum up maintenance amounts
    for (final doc in maintenanceSnapshot.docs) {
      maintenanceCollected += (doc.data()['total_collected'] as num?)?.toDouble() ?? 0.0;
      maintenancePending += (doc.data()['total_pending'] as num?)?.toDouble() ?? 0.0;
    }

    // Get total expenses
    final expensesSnapshot = await FirebaseFirestore.instance.collection('expenses').get();
    double totalExpenses = 0.0;

    for (final doc in expensesSnapshot.docs) {
      totalExpenses += (doc.data()['total_amount'] as num?)?.toDouble() ?? 0.0;
    }

    return DashboardStatsModel(
      totalMembers: totalMembers,
      totalExpenses: totalExpenses,
      maintenanceCollected: maintenanceCollected,
      maintenancePending: maintenancePending,
      activeMaintenance: activeMaintenance,
      fullyPaidUsers: fullyPaidUsers,
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
        'fully_paid': 0,
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
      'fully_paid': lineStats.fullyPaidUsers,
      'line_number': lineNumber,
      'updated_at': now,
    });

    // Update user dashboard for this line - use the same data as line head dashboard
    await _userDashboardCollection.doc(lineNumber).set({
      'total_members': lineStats.totalMembers,
      'total_expenses': lineStats.totalExpenses,
      'maintenance_collected': lineStats.maintenanceCollected,
      'maintenance_pending': lineStats.maintenancePending,
      'active_maintenance': lineStats.activeMaintenance,
      'fully_paid': lineStats.fullyPaidUsers,
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
    int fullyPaidUsers = 0;

    // Count active maintenance periods
    final maintenanceSnapshot = await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();

    activeMaintenance = maintenanceSnapshot.docs.length;

    // For each active period, get payments for this line
    if (maintenanceSnapshot.docs.isNotEmpty) {
      // Get the most recent period for fully paid count
      final latestPeriod = maintenanceSnapshot.docs.first;
      final periodId = latestPeriod.id;
      final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
          .where('period_id', isEqualTo: periodId)
          .where('user_line_number', isEqualTo: lineNumber)
          .get();

      // Count fully paid users in the latest period
      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final userRole =
            paymentData['user_id'] == 'admin' || (paymentData['user_name'] as String?)?.toLowerCase() == 'admin';

        // Skip admin users
        if (userRole) continue;

        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0.0;

        // Count fully paid users
        if (amountPaid >= amount && amount > 0) {
          fullyPaidUsers++;
        }
      }
    }

    // For all active periods, calculate collected and pending amounts
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
      fullyPaidUsers: fullyPaidUsers,
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
        'fully_paid': 0,
        'updated_at': now,
      });
    }
  }

  // Method to update dashboard stats when maintenance is recorded
  @override
  Future<void> updateDashboardsForMaintenancePayment({
    required String lineNumber,
    required double amountPaid,
    required double amountPending,
    bool isFullyPaid = false,
    String? userId, // Add userId parameter
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
      final currentFullyPaid = data?['fully_paid'] as int? ?? 0;

      // Update fully paid count if this payment makes the user fully paid
      final fullyPaidUpdate = isFullyPaid ? {'fully_paid': currentFullyPaid + 1} : <String, dynamic>{};

      batch.update(lineHeadStatsRef, {
        'maintenance_collected': currentCollected + amountPaid,
        'maintenance_pending': currentPending - amountPaid + amountPending,
        'updated_at': now,
        ...fullyPaidUpdate,
      });
    }

    // Update line-wide user dashboard
    final userStatsRef = _userDashboardCollection.doc(lineNumber);
    final userStatsDoc = await userStatsRef.get();

    if (userStatsDoc.exists) {
      final data = userStatsDoc.data() as Map<String, dynamic>?;
      final currentCollected = data?['maintenance_collected'] as double? ?? 0.0;
      final currentPending = data?['maintenance_pending'] as double? ?? 0.0;
      final currentFullyPaid = data?['fully_paid'] as int? ?? 0;

      // Update fully paid count if this payment makes the user fully paid
      final fullyPaidUpdate = isFullyPaid ? {'fully_paid': currentFullyPaid + 1} : <String, dynamic>{};

      batch.update(userStatsRef, {
        'maintenance_collected': currentCollected + amountPaid,
        'maintenance_pending': currentPending - amountPaid + amountPending,
        'updated_at': now,
        ...fullyPaidUpdate,
      });
    }

    // Commit the batch
    await batch.commit();

    // Update user-specific stats if userId is provided
    if (userId != null) {
      try {
        // Instead of updating the stats directly, recalculate them completely
        // This ensures we have accurate data
        await updateUserStats(userId, lineNumber);

        // Log for debugging
        debugPrint('Updated user-specific stats for user $userId in line $lineNumber');
      } catch (e) {
        debugPrint('Error updating user-specific stats: $e');
      }
    }
  }

  // Method to update dashboard stats when a maintenance period is created
  @override
  Future<void> updateDashboardsForMaintenancePeriodCreation() async {
    // Recalculate all stats
    await updateAdminDashboardStats();
    await _updateAllLineStats();

    // Update user-specific stats for all users
    try {
      final usersSnapshot = await FirebaseFirestore.instance.users.get();
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final lineNumber = userDoc.data()['line_number'] as String?;

        if (lineNumber != null) {
          await updateUserStats(userId, lineNumber);
        }
      }
    } catch (e) {
      debugPrint('Error updating user-specific stats for all users: $e');
    }
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
        'fully_paid': stats.fullyPaidUsers,
        'updated_at': now,
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't fail the update
      debugPrint('Error updating admin dashboard stats: $e');
    }
  }

  // Method to get user dashboard stats - shows only the logged-in user's data
  @override
  FirebaseResult<DashboardStatsModel> getUserStats(String lineNumber) {
    return Result<DashboardStatsModel>().tryCatch(
      run: () async {
        // Get the current user ID
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No user is currently logged in');
        }

        final userId = currentUser.uid;

        // Check if we have cached stats for this user
        final userStatsDoc = await FirebaseFirestore.instance.collection('user_specific_stats').doc(userId).get();

        if (userStatsDoc.exists) {
          // Update stats in the background but return cached stats immediately
          updateUserStats(userId, lineNumber); // Don't await this
          return DashboardStatsModel.fromJson(userStatsDoc.data() as Map<String, dynamic>);
        }

        // If no cached stats, calculate them
        final stats = await _calculateUserStats(userId, lineNumber);

        // Cache the stats for future use
        await updateUserStats(userId, lineNumber);

        return stats;
      },
    );
  }

  // Helper method to calculate stats for a specific user
  Future<DashboardStatsModel> _calculateUserStats(String userId, String lineNumber) async {
    final now = Timestamp.now();

    // Initialize stats
    int totalMembers = 1; // Just the user
    double maintenanceCollected = 0.0;
    double maintenancePending = 0.0;
    int activeMaintenance = 0;
    int fullyPaidUsers = 0;
    double totalExpenses = 0.0;

    try {
      // Count active maintenance periods
      final maintenanceSnapshot =
          await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();
      activeMaintenance = maintenanceSnapshot.docs.length;

      // Debug log
      debugPrint('Active maintenance periods: $activeMaintenance');

      // Calculate for ALL active periods
      maintenancePending = 0.0; // Reset pending amount

      if (maintenanceSnapshot.docs.isNotEmpty) {
        // Get the default amount per user from the first period
        final defaultAmount = (maintenanceSnapshot.docs.first.data()['amount_per_user'] as num?)?.toDouble() ?? 1000.0;

        // Debug log
        debugPrint('Default amount per user: $defaultAmount');
        debugPrint('Number of active periods: ${maintenanceSnapshot.docs.length}');

        // For each active period, check if there's a payment record
        for (final periodDoc in maintenanceSnapshot.docs) {
          final periodId = periodDoc.id;

          // Debug log
          debugPrint('Processing active period ID: $periodId');

          // Get this user's payment for this period
          final paymentSnapshot = await FirebaseFirestore.instance.maintenancePayments
              .where('period_id', isEqualTo: periodId)
              .where('user_id', isEqualTo: userId)
              .get();

          // Check if user has a payment record for this period
          if (paymentSnapshot.docs.isNotEmpty) {
            final paymentDoc = paymentSnapshot.docs.first;
            final paymentData = paymentDoc.data();

            final amount = (paymentData['amount'] as num?)?.toDouble() ?? defaultAmount;
            final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0.0;

            // Debug log
            debugPrint('Period $periodId - Amount: $amount, Paid: $amountPaid');

            // Add to pending amount if not fully paid
            if (amount > amountPaid) {
              final pendingForThisPeriod = amount - amountPaid;
              maintenancePending += pendingForThisPeriod;
              debugPrint('Adding to pending: $pendingForThisPeriod, Total pending now: $maintenancePending');
            }

            // Check if fully paid for the latest period (first in the list)
            if (periodDoc == maintenanceSnapshot.docs.first) {
              if (amountPaid >= amount && amount > 0) {
                fullyPaidUsers = 1;
                debugPrint('User is fully paid for the latest period');
              } else {
                fullyPaidUsers = 0;
                debugPrint('User is NOT fully paid for the latest period');
              }

              // Also check payment status from the payment record
              final paymentStatus = paymentData['status'] as String?;
              if (paymentStatus == 'paid') {
                fullyPaidUsers = 1;
                debugPrint('User payment status is explicitly marked as PAID');
              }
            }
          } else {
            // If no payment record exists, the full amount is pending for this period
            maintenancePending += defaultAmount;
            debugPrint('No payment record found for period $periodId, adding default amount: $defaultAmount');

            // If this is the latest period, mark as not fully paid
            if (periodDoc == maintenanceSnapshot.docs.first) {
              fullyPaidUsers = 0;
              debugPrint('No payment record for latest period, marking as not fully paid');
            }
          }
        }

        // Final debug log for pending amount
        debugPrint('Final pending amount for all active periods: $maintenancePending');
      }

      // Calculate total collected amount across all periods
      maintenanceCollected = 0.0; // Reset to ensure accurate calculation

      // Get all payments for this user (not just active periods)
      final allPaymentsSnapshot =
          await FirebaseFirestore.instance.maintenancePayments.where('user_id', isEqualTo: userId).get();

      // Debug log
      debugPrint('Total payment records found: ${allPaymentsSnapshot.docs.length}');

      // Check if any payment is marked as paid for the latest period
      if (maintenanceSnapshot.docs.isNotEmpty && allPaymentsSnapshot.docs.isNotEmpty) {
        final latestPeriodId = maintenanceSnapshot.docs.first.id;

        // Find payment for the latest period
        final latestPayments =
            allPaymentsSnapshot.docs.where((doc) => doc.data()['period_id'] == latestPeriodId).toList();

        if (latestPayments.isNotEmpty) {
          final latestPayment = latestPayments.first;
          final paymentStatus = latestPayment.data()['status'] as String?;

          // If payment status is explicitly 'paid', mark as fully paid
          if (paymentStatus == 'paid') {
            fullyPaidUsers = 1;
            debugPrint('Found payment with status PAID for latest period');
          }
        }
      }

      // Sum up all amounts paid
      for (final paymentDoc in allPaymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0.0;
        final periodId = paymentData['period_id'] as String?;

        // Debug log
        debugPrint('Payment for period $periodId: $amountPaid');

        // Add to collected amount
        maintenanceCollected += amountPaid;
      }

      // Final check: if user has no pending amount, mark as fully paid
      if (maintenancePending <= 0 && activeMaintenance > 0) {
        fullyPaidUsers = 1;
        debugPrint('User has no pending amount, marking as fully paid');
      }

      // Debug log
      debugPrint(
          'Final calculations - Collected: $maintenanceCollected, Pending: $maintenancePending, Fully Paid: $fullyPaidUsers');
    } catch (e) {
      debugPrint('Error calculating user stats: $e');
    }

    return DashboardStatsModel(
      totalMembers: totalMembers,
      totalExpenses: totalExpenses,
      maintenanceCollected: maintenanceCollected,
      maintenancePending: maintenancePending,
      activeMaintenance: activeMaintenance,
      fullyPaidUsers: fullyPaidUsers,
      updatedAt: now.toDate().toString(),
    );
  }

  // Method to update stats for a specific user
  Future<void> updateUserStats(String userId, String lineNumber) async {
    final userStats = await _calculateUserStats(userId, lineNumber);
    final now = Timestamp.now();

    // Update user-specific stats collection
    await FirebaseFirestore.instance.collection('user_specific_stats').doc(userId).set({
      'total_members': userStats.totalMembers,
      'total_expenses': userStats.totalExpenses,
      'maintenance_collected': userStats.maintenanceCollected,
      'maintenance_pending': userStats.maintenancePending,
      'active_maintenance': userStats.activeMaintenance,
      'fully_paid': userStats.fullyPaidUsers,
      'line_number': lineNumber,
      'updated_at': now,
    });
  }
}

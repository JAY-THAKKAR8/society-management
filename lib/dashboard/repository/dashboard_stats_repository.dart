import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  FirebaseResult<DashboardStatsModel> getDashboardStats() {
    return Result<DashboardStatsModel>().tryCatch(
      run: () async {
        final statsDoc = await FirebaseFirestore.instance.dashboardStats.doc('stats').get();
        final now = Timestamp.now();

        // Get maintenance stats
        double maintenanceCollected = 0.0;
        double maintenancePending = 0.0;
        int activeMaintenance = 0;

        // Count total members (excluding admins)
        // We can't use multiple isNotEqualTo filters, so we'll get all users and filter in memory
        final usersSnapshot = await FirebaseFirestore.instance.users.get();
        final totalMembers = usersSnapshot.docs.where((doc) {
          final role = doc.data()['role'] as String?;
          return role != 'admin' && role != 'ADMIN' && role != AppConstants.admins;
        }).length;

        // Count active maintenance periods
        final maintenanceSnapshot =
            await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();

        activeMaintenance = maintenanceSnapshot.docs.length;

        // Sum up maintenance amounts
        for (final doc in maintenanceSnapshot.docs) {
          maintenanceCollected += (doc.data()['total_collected'] as num?)?.toDouble() ?? 0.0;
          maintenancePending += (doc.data()['total_pending'] as num?)?.toDouble() ?? 0.0;
        }

        if (!statsDoc.exists) {
          // Create initial stats document if it doesn't exist
          await FirebaseFirestore.instance.dashboardStats.doc('stats').set({
            'total_members': totalMembers,
            'total_expenses': 0.0,
            'maintenance_collected': maintenanceCollected,
            'maintenance_pending': maintenancePending,
            'active_maintenance': activeMaintenance,
            'updated_at': now,
          });

          return DashboardStatsModel(
            totalMembers: totalMembers,
            totalExpenses: 0.0,
            maintenanceCollected: maintenanceCollected,
            maintenancePending: maintenancePending,
            activeMaintenance: activeMaintenance,
            updatedAt: now.toDate().toString(),
          );
        }

        // Update the stats document with maintenance information and member count
        await FirebaseFirestore.instance.dashboardStats.doc('stats').update({
          'total_members': totalMembers,
          'maintenance_collected': maintenanceCollected,
          'maintenance_pending': maintenancePending,
          'active_maintenance': activeMaintenance,
          'updated_at': now,
        });

        // Get the updated document
        final updatedStatsDoc = await FirebaseFirestore.instance.dashboardStats.doc('stats').get();
        return DashboardStatsModel.fromJson(updatedStatsDoc.data()!);
      },
    );
  }

  @override
  FirebaseResult<void> incrementTotalMembers() {
    return Result<void>().tryCatch(
      run: () async {
        final statsRef = FirebaseFirestore.instance.dashboardStats.doc('stats');

        return FirebaseFirestore.instance.runTransaction((transaction) async {
          final statsDoc = await transaction.get(statsRef);

          if (!statsDoc.exists) {
            transaction.set(statsRef, {
              'total_members': 1,
              'total_expenses': 0.0,
              'updated_at': Timestamp.now(),
            });
          } else {
            final currentCount = statsDoc.data()?['total_members'] as int? ?? 0;
            transaction.update(statsRef, {
              'total_members': currentCount + 1,
              'updated_at': Timestamp.now(),
            });
          }
        });
      },
    );
  }

  @override
  FirebaseResult<DashboardStatsModel> getLineStats(String lineNumber) {
    return Result<DashboardStatsModel>().tryCatch(
      run: () async {
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
        final maintenanceSnapshot =
            await FirebaseFirestore.instance.maintenance.where('is_active', isEqualTo: true).get();

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

        // Get total expenses (we'll use the same as global for now)
        final statsDoc = await FirebaseFirestore.instance.dashboardStats.doc('stats').get();
        double totalExpenses = 0.0;

        if (statsDoc.exists) {
          totalExpenses = (statsDoc.data()?['total_expenses'] as num?)?.toDouble() ?? 0.0;
        }

        return DashboardStatsModel(
          totalMembers: totalMembers,
          totalExpenses: totalExpenses,
          maintenanceCollected: maintenanceCollected,
          maintenancePending: maintenancePending,
          activeMaintenance: activeMaintenance,
          updatedAt: now.toDate().toString(),
        );
      },
    );
  }

  @override
  FirebaseResult<void> incrementTotalExpenses(double amount) {
    return Result<void>().tryCatch(
      run: () async {
        final statsRef = FirebaseFirestore.instance.dashboardStats.doc('stats');

        return FirebaseFirestore.instance.runTransaction((transaction) async {
          final statsDoc = await transaction.get(statsRef);

          if (!statsDoc.exists) {
            transaction.set(statsRef, {
              'total_members': 0,
              'total_expenses': amount,
              'updated_at': Timestamp.now(),
            });
          } else {
            final currentAmount = statsDoc.data()?['total_expenses'] as double? ?? 0.0;
            transaction.update(statsRef, {
              'total_expenses': currentAmount + amount,
              'updated_at': Timestamp.now(),
            });
          }
        });
      },
    );
  }
}

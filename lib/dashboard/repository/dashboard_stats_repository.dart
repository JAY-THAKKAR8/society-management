import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
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

        if (!statsDoc.exists) {
          // Create initial stats document if it doesn't exist
          await FirebaseFirestore.instance.dashboardStats.doc('stats').set({
            'total_members': 0,
            'total_expenses': 0.0,
            'updated_at': Timestamp.now(),
          });

          return const DashboardStatsModel(
            totalMembers: 0,
            totalExpenses: 0.0,
            updatedAt: null,
          );
        }

        return DashboardStatsModel.fromJson(statsDoc.data()!);
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

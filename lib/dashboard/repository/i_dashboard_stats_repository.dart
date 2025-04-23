import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IDashboardStatsRepository {
  final FirebaseFirestore firestore;
  IDashboardStatsRepository(this.firestore);

  FirebaseResult<DashboardStatsModel> getDashboardStats();

  FirebaseResult<void> incrementTotalMembers();

  FirebaseResult<void> incrementTotalExpenses(double amount);
}

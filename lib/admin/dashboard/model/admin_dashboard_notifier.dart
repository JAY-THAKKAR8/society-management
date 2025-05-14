import 'package:flutter/foundation.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/utility.dart';

class AdminDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final DashboardStatsModel? stats;

  AdminDashboardState({
    this.isLoading = true,
    this.errorMessage,
    this.stats,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    DashboardStatsModel? stats,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
    );
  }

  String calculateCollectionRate() {
    if (stats == null) return "0%";
    
    final total = stats!.maintenanceCollected + stats!.maintenancePending;
    if (total <= 0) return "0%";
    
    final rate = (stats!.maintenanceCollected / total) * 100;
    return "${rate.toStringAsFixed(1)}%";
  }
}

class AdminDashboardNotifier extends ValueNotifier<AdminDashboardState> {
  final IDashboardStatsRepository _statsRepository = getIt<IDashboardStatsRepository>();
  
  AdminDashboardNotifier() : super(AdminDashboardState());

  Future<void> refreshStats() async {
    try {
      value = value.copyWith(isLoading: true, errorMessage: null);

      final result = await _statsRepository.getDashboardStats();

      result.fold(
        (failure) {
          value = value.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          Utility.toast(message: failure.message);
        },
        (stats) {
          value = value.copyWith(
            stats: stats,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      value = value.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      Utility.toast(message: 'Error fetching dashboard stats: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/auth/service/auth_service.dart';

class DashboardState {
  final bool isLoading;
  final bool isUserLoading;
  final String? errorMessage;
  final DashboardStatsModel? stats;
  final UserModel? currentUser;

  DashboardState({
    this.isLoading = true,
    this.isUserLoading = true,
    this.errorMessage,
    this.stats,
    this.currentUser,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isUserLoading,
    String? errorMessage,
    DashboardStatsModel? stats,
    UserModel? currentUser,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isUserLoading: isUserLoading ?? this.isUserLoading,
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class DashboardNotifier extends ValueNotifier<DashboardState> {
  final IDashboardStatsRepository _statsRepository = getIt<IDashboardStatsRepository>();
  final AuthService _authService = AuthService();
  
  DashboardNotifier() : super(DashboardState()) {
    loadCurrentUser();
    refreshStats();
  }

  Future<void> loadCurrentUser() async {
    try {
      value = value.copyWith(isUserLoading: true);
      
      final user = await _authService.getCurrentUser();
      
      value = value.copyWith(
        currentUser: user,
        isUserLoading: false,
      );
    } catch (e) {
      value = value.copyWith(
        isUserLoading: false,
        errorMessage: 'Error loading user: $e',
      );
      Utility.toast(message: 'Error loading user: $e');
    }
  }

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

  Future<void> logout() async {
    try {
      await _authService.signOut();
      return Future.value();
    } catch (e) {
      Utility.toast(message: 'Error logging out: $e');
      return Future.error(e);
    }
  }
}

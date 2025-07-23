import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/dashboard/service/dashboard_stats_service.dart';

/// Simple Dashboard Cubit for managing dashboard state across the app
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardStatsService _statsService = DashboardStatsService();

  DashboardCubit() : super(DashboardState.initial());

  // ========================================
  // EXPENSE OPERATIONS
  // ========================================

  /// Add new expense and update all dashboards
  Future<void> addExpense(double amount) async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.addExpense(amount);

      emit(state.copyWith(
        isLoading: false,
        totalExpenses: state.totalExpenses + amount,
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard updated: Added expense ₹$amount');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to add expense: $e',
      ));
    }
  }

  /// Remove expense and update all dashboards
  Future<void> removeExpense(double amount) async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.removeExpense(amount);

      emit(state.copyWith(
        isLoading: false,
        totalExpenses: state.totalExpenses - amount,
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard updated: Removed expense ₹$amount');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to remove expense: $e',
      ));
    }
  }

  /// Update expense amount and update all dashboards
  Future<void> updateExpense({
    required double oldAmount,
    required double newAmount,
  }) async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.updateExpense(
        oldAmount: oldAmount,
        newAmount: newAmount,
      );

      final difference = newAmount - oldAmount;
      emit(state.copyWith(
        isLoading: false,
        totalExpenses: state.totalExpenses + difference,
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard updated: Updated expense ₹$oldAmount → ₹$newAmount');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to update expense: $e',
      ));
    }
  }

  // ========================================
  // USER OPERATIONS
  // ========================================

  /// Add new user and update dashboards
  Future<void> addUser() async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.addUser();

      emit(state.copyWith(
        isLoading: false,
        totalMembers: state.totalMembers + 1,
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard updated: Added new user');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to add user: $e',
      ));
    }
  }

  /// Remove user and update dashboards
  Future<void> removeUser() async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.removeUser();

      emit(state.copyWith(
        isLoading: false,
        totalMembers: state.totalMembers - 1,
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard updated: Removed user');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to remove user: $e',
      ));
    }
  }

  // ========================================
  // MAINTENANCE OPERATIONS
  // ========================================

  /// Update maintenance stats
  Future<void> updateMaintenance({
    double? collectedChange,
    double? pendingChange,
    int? fullyPaidChange,
  }) async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.updateMaintenance(
        collectedChange: collectedChange,
        pendingChange: pendingChange,
        fullyPaidChange: fullyPaidChange,
      );

      emit(state.copyWith(
        isLoading: false,
        maintenanceCollected: state.maintenanceCollected + (collectedChange ?? 0),
        maintenancePending: state.maintenancePending + (pendingChange ?? 0),
        fullyPaidUsers: state.fullyPaidUsers + (fullyPaidChange ?? 0),
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard updated: Updated maintenance stats');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to update maintenance: $e',
      ));
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Refresh all dashboard data
  Future<void> refresh() async {
    try {
      emit(state.copyWith(isLoading: true));

      await _statsService.recalculateAllStats();

      emit(state.copyWith(
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      print('✅ Dashboard refreshed');
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to refresh dashboard: $e',
      ));
    }
  }

  /// Clear any error state
  void clearError() {
    emit(state.copyWith(error: null));
  }
}

/// Simple Dashboard State
class DashboardState {
  final bool isLoading;
  final String? error;
  final double totalExpenses;
  final int totalMembers;
  final double maintenanceCollected;
  final double maintenancePending;
  final int fullyPaidUsers;
  final DateTime? lastUpdated;

  const DashboardState({
    required this.isLoading,
    this.error,
    required this.totalExpenses,
    required this.totalMembers,
    required this.maintenanceCollected,
    required this.maintenancePending,
    required this.fullyPaidUsers,
    this.lastUpdated,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      totalExpenses: 0.0,
      totalMembers: 0,
      maintenanceCollected: 0.0,
      maintenancePending: 0.0,
      fullyPaidUsers: 0,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    double? totalExpenses,
    int? totalMembers,
    double? maintenanceCollected,
    double? maintenancePending,
    int? fullyPaidUsers,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalMembers: totalMembers ?? this.totalMembers,
      maintenanceCollected: maintenanceCollected ?? this.maintenanceCollected,
      maintenancePending: maintenancePending ?? this.maintenancePending,
      fullyPaidUsers: fullyPaidUsers ?? this.fullyPaidUsers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

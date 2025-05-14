import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/utility.dart';

class LineHeadDashboardState {
  final bool isLoading;
  final bool isUserLoading;
  final bool isStatsLoading;
  final String? errorMessage;
  final UserModel? currentUser;
  
  // Line stats
  final int lineMembers;
  final int pendingPayments;
  final int fullyPaidUsers;
  final double pendingAmount;
  final double collectedAmount;
  final int activeMaintenancePeriods;
  
  // Pending maintenance alert
  final List<MaintenancePeriodModel> pendingPeriods;
  final Map<String, List<MaintenancePaymentModel>> pendingPaymentsByPeriod;

  LineHeadDashboardState({
    this.isLoading = true,
    this.isUserLoading = true,
    this.isStatsLoading = true,
    this.errorMessage,
    this.currentUser,
    this.lineMembers = 0,
    this.pendingPayments = 0,
    this.fullyPaidUsers = 0,
    this.pendingAmount = 0.0,
    this.collectedAmount = 0.0,
    this.activeMaintenancePeriods = 0,
    this.pendingPeriods = const [],
    this.pendingPaymentsByPeriod = const {},
  });

  LineHeadDashboardState copyWith({
    bool? isLoading,
    bool? isUserLoading,
    bool? isStatsLoading,
    String? errorMessage,
    UserModel? currentUser,
    int? lineMembers,
    int? pendingPayments,
    int? fullyPaidUsers,
    double? pendingAmount,
    double? collectedAmount,
    int? activeMaintenancePeriods,
    List<MaintenancePeriodModel>? pendingPeriods,
    Map<String, List<MaintenancePaymentModel>>? pendingPaymentsByPeriod,
  }) {
    return LineHeadDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isUserLoading: isUserLoading ?? this.isUserLoading,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      errorMessage: errorMessage,
      currentUser: currentUser ?? this.currentUser,
      lineMembers: lineMembers ?? this.lineMembers,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      fullyPaidUsers: fullyPaidUsers ?? this.fullyPaidUsers,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      activeMaintenancePeriods: activeMaintenancePeriods ?? this.activeMaintenancePeriods,
      pendingPeriods: pendingPeriods ?? this.pendingPeriods,
      pendingPaymentsByPeriod: pendingPaymentsByPeriod ?? this.pendingPaymentsByPeriod,
    );
  }
}

class LineHeadDashboardNotifier extends ValueNotifier<LineHeadDashboardState> {
  final AuthService _authService = AuthService();
  final IDashboardStatsRepository _statsRepository = getIt<IDashboardStatsRepository>();
  final IMaintenanceRepository _maintenanceRepository = getIt<IMaintenanceRepository>();
  
  LineHeadDashboardNotifier() : super(LineHeadDashboardState()) {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      value = value.copyWith(isUserLoading: true);
      
      final user = await _authService.getCurrentUser();
      
      // Verify this is a line head or line head + member
      if (user != null && !user.isLineHead) {
        Utility.toast(message: 'Access denied: Not a line head');
        await logout();
        return;
      }
      
      value = value.copyWith(
        currentUser: user,
        isUserLoading: false,
      );
      
      // Load stats after user is loaded
      if (user?.lineNumber != null) {
        loadStats(user!.lineNumber!);
        checkPendingMaintenance(user.lineNumber!);
      }
    } catch (e) {
      value = value.copyWith(
        isUserLoading: false,
        errorMessage: 'Error loading user: $e',
      );
      Utility.toast(message: 'Error loading user: $e');
    }
  }

  Future<void> loadStats(String lineNumber) async {
    try {
      value = value.copyWith(isStatsLoading: true);
      
      // Get line stats
      final result = await _statsRepository.getLineStats(lineNumber);
      
      result.fold(
        (failure) {
          value = value.copyWith(
            isStatsLoading: false,
            errorMessage: failure.message,
          );
          Utility.toast(message: failure.message);
        },
        (stats) async {
          // Update basic stats
          value = value.copyWith(
            lineMembers: stats.totalMembers,
            pendingAmount: stats.maintenancePending,
            collectedAmount: stats.maintenanceCollected,
            activeMaintenancePeriods: stats.activeMaintenance,
            isStatsLoading: false,
          );
          
          // Get more detailed payment stats
          await _updatePaymentStats(lineNumber, stats.totalMembers);
        },
      );
    } catch (e) {
      value = value.copyWith(
        isStatsLoading: false,
        errorMessage: 'Error loading stats: $e',
      );
      Utility.toast(message: 'Error loading stats: $e');
    }
  }
  
  Future<void> _updatePaymentStats(String lineNumber, int totalMembers) async {
    try {
      if (totalMembers <= 0) {
        value = value.copyWith(
          pendingPayments: 0,
          fullyPaidUsers: 0,
        );
        return;
      }
      
      // Get active maintenance periods
      final periodsResult = await _maintenanceRepository.getActiveMaintenancePeriods();
      
      periodsResult.fold(
        (failure) {
          // Use approximate counts if we can't get detailed data
          if (value.pendingAmount > 0) {
            value = value.copyWith(
              pendingPayments: totalMembers,
              fullyPaidUsers: 0,
            );
          } else {
            value = value.copyWith(
              pendingPayments: 0,
              fullyPaidUsers: totalMembers,
            );
          }
        },
        (periods) async {
          if (periods.isEmpty) {
            value = value.copyWith(
              pendingPayments: 0,
              fullyPaidUsers: 0,
            );
            return;
          }
          
          // Get payments for the most recent period
          final latestPeriod = periods.first;
          if (latestPeriod.id == null) return;
          
          final paymentsResult = await _maintenanceRepository.getPaymentsForLine(
            periodId: latestPeriod.id!,
            lineNumber: lineNumber,
          );
          
          paymentsResult.fold(
            (failure) {
              // Use approximate counts if we can't get detailed data
              if (value.pendingAmount > 0) {
                value = value.copyWith(
                  pendingPayments: totalMembers,
                  fullyPaidUsers: 0,
                );
              } else {
                value = value.copyWith(
                  pendingPayments: 0,
                  fullyPaidUsers: totalMembers,
                );
              }
            },
            (payments) {
              int pendingPayments = 0;
              int fullyPaidUsers = 0;
              
              for (final payment in payments) {
                final amount = payment.amount ?? 0.0;
                final amountPaid = payment.amountPaid;
                
                if (amountPaid >= amount && amount > 0) {
                  fullyPaidUsers++;
                } else if (amount > 0) {
                  pendingPayments++;
                }
              }
              
              value = value.copyWith(
                pendingPayments: pendingPayments,
                fullyPaidUsers: fullyPaidUsers,
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error updating payment stats: $e');
    }
  }

  Future<void> checkPendingMaintenance(String lineNumber) async {
    try {
      // Get active maintenance periods
      final periodsResult = await _maintenanceRepository.getActiveMaintenancePeriods();
      
      periodsResult.fold(
        (failure) {
          debugPrint('Error checking maintenance periods: ${failure.message}');
        },
        (periods) async {
          if (periods.isEmpty) return;
          
          final pendingPeriods = <MaintenancePeriodModel>[];
          final pendingPaymentsByPeriod = <String, List<MaintenancePaymentModel>>{};
          
          // For each active period, check if there are pending payments in this line
          for (final period in periods) {
            if (period.id == null) continue;
            
            final paymentsResult = await _maintenanceRepository.getPaymentsForLine(
              periodId: period.id!,
              lineNumber: lineNumber,
            );
            
            paymentsResult.fold(
              (failure) {
                debugPrint('Error checking payments: ${failure.message}');
              },
              (payments) {
                // Count pending payments
                final pendingPayments = payments
                    .where((payment) => 
                        payment.status == PaymentStatus.pending || 
                        payment.status == PaymentStatus.overdue)
                    .toList();
                
                if (pendingPayments.isNotEmpty) {
                  pendingPeriods.add(period);
                  pendingPaymentsByPeriod[period.id!] = pendingPayments;
                }
              },
            );
          }
          
          value = value.copyWith(
            pendingPeriods: pendingPeriods,
            pendingPaymentsByPeriod: pendingPaymentsByPeriod,
          );
        },
      );
    } catch (e) {
      debugPrint('Error in checkPendingMaintenance: $e');
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
  
  void refreshAll() {
    if (value.currentUser?.lineNumber != null) {
      loadStats(value.currentUser!.lineNumber!);
      checkPendingMaintenance(value.currentUser!.lineNumber!);
    }
  }
}

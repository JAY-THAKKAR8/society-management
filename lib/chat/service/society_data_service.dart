import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';

/// Service to fetch society data for AI analysis
class SocietyDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final IDashboardStatsRepository _statsRepository = getIt<IDashboardStatsRepository>();
  final IMaintenanceRepository _maintenanceRepository = getIt<IMaintenanceRepository>();

  /// Get current user information
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {'error': 'No user is currently logged in'};
      }

      return {
        'id': currentUser.id,
        'name': currentUser.name,
        'email': currentUser.email,
        'role': currentUser.role,
        'lineNumber': currentUser.lineNumber,
        'villNumber': currentUser.villNumber,
        'mobileNumber': currentUser.mobileNumber,
      };
    } catch (e) {
      return {'error': 'Error fetching current user: $e'};
    }
  }

  /// Get society dashboard statistics
  Future<Map<String, dynamic>> getSocietyStats() async {
    try {
      final result = await _statsRepository.getDashboardStats();

      return result.fold(
        (failure) => {'error': failure.message},
        (stats) => {
          'totalMembers': stats.totalMembers,
          'totalExpenses': stats.totalExpenses,
          'maintenanceCollected': stats.maintenanceCollected,
          'maintenancePending': stats.maintenancePending,
          'activeMaintenance': stats.activeMaintenance,
          'updatedAt': stats.updatedAt,
        },
      );
    } catch (e) {
      return {'error': 'Error fetching society stats: $e'};
    }
  }

  /// Get active maintenance periods
  Future<Map<String, dynamic>> getActiveMaintenancePeriods() async {
    try {
      final result = await _maintenanceRepository.getActiveMaintenancePeriods();

      return result.fold(
        (failure) => {'error': failure.message},
        (periods) => {
          'count': periods.length,
          'periods': periods
              .map((period) => {
                    'id': period.id,
                    'name': period.name,
                    'amount': period.amount,
                    'startDate': period.startDate?.toString(),
                    'dueDate': period.dueDate?.toString(),
                    'status': 'active',
                  })
              .toList(),
        },
      );
    } catch (e) {
      return {'error': 'Error fetching maintenance periods: $e'};
    }
  }

  /// Get user's pending maintenance payments
  Future<Map<String, dynamic>> getUserPendingPayments() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {'error': 'No user is currently logged in'};
      }

      final userId = currentUser.id;
      if (userId == null) {
        return {'error': 'User ID is null'};
      }

      // Get all active maintenance periods
      final periodsResult = await _maintenanceRepository.getActiveMaintenancePeriods();

      return await periodsResult.fold(
        (failure) async => {'error': failure.message},
        (periods) async {
          final pendingPayments = <Map<String, dynamic>>[];

          for (final period in periods) {
            if (period.id == null) continue;

            // Get user's payment for this period
            final paymentsSnapshot = await _firestore.maintenancePayments
                .where('period_id', isEqualTo: period.id)
                .where('user_id', isEqualTo: userId)
                .get();

            for (final doc in paymentsSnapshot.docs) {
              final payment = MaintenancePaymentModel.fromJson(doc.data());

              // Only include pending or partially paid payments
              if (payment.status == PaymentStatus.pending ||
                  payment.status == PaymentStatus.partiallyPaid ||
                  payment.status == PaymentStatus.overdue) {
                pendingPayments.add({
                  'periodId': payment.periodId,
                  'periodName': period.name,
                  'amount': payment.amount,
                  'amountPaid': payment.amountPaid,
                  'amountDue': (payment.amount ?? 0) - (payment.amountPaid ?? 0),
                  'status': payment.status.toString().split('.').last,
                  'dueDate': period.dueDate?.toString(),
                });
              }
            }
          }

          return {
            'count': pendingPayments.length,
            'payments': pendingPayments,
            'totalDue': pendingPayments.fold(0.0, (total, payment) => total + (payment['amountDue'] as double? ?? 0.0)),
          };
        },
      );
    } catch (e) {
      return {'error': 'Error fetching pending payments: $e'};
    }
  }

  /// Get all society data for AI analysis
  Future<Map<String, dynamic>> getAllSocietyData() async {
    final userData = await getCurrentUserInfo();
    final societyStats = await getSocietyStats();
    final maintenancePeriods = await getActiveMaintenancePeriods();
    final pendingPayments = await getUserPendingPayments();

    return {
      'currentUser': userData,
      'societyStats': societyStats,
      'maintenancePeriods': maintenancePeriods,
      'pendingPayments': pendingPayments,
      'timestamp': DateTime.now().toString(),
    };
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/failure/custom_failure.dart';

/// Service for automatically creating maintenance periods
class AutoMaintenanceService {
  final IMaintenanceRepository _maintenanceRepository;

  AutoMaintenanceService({IMaintenanceRepository? maintenanceRepository})
      : _maintenanceRepository = maintenanceRepository ?? getIt<IMaintenanceRepository>();

  /// Check if it's time to create a new maintenance period
  /// Returns true if today is the 25th of the month and no period exists for next month
  Future<bool> shouldCreateNewPeriod() async {
    // Check if today is the 25th of the month
    final now = DateTime.now();
    if (now.day != 25) {
      return false;
    }

    // Get all maintenance periods
    final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();

    return periodsResult.fold(
      (failure) => false, // If there's an error, don't create a new period
      (periods) {
        // Calculate next month's start and end dates
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final nextMonthName = DateFormat('MMMM yyyy').format(nextMonth);

        // Check if a period already exists for next month
        final existingPeriod = periods.any((period) =>
            period.name?.toLowerCase() == nextMonthName.toLowerCase() ||
            (period.startDate != null &&
                DateTime.parse(period.startDate!).month == nextMonth.month &&
                DateTime.parse(period.startDate!).year == nextMonth.year));

        // Return true if no period exists for next month
        return !existingPeriod;
      },
    );
  }

  /// Create a new maintenance period for the next month
  Future<EitherResult<MaintenancePeriodModel>> createNextMonthPeriod({
    double? defaultAmount,
  }) async {
    try {
      final now = DateTime.now();

      // Calculate next month's dates
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextMonthEnd = DateTime(now.year, now.month + 2, 0); // Last day of next month
      final nextMonthDueDate = DateTime(now.year, now.month + 1, 10); // Due on 10th of next month

      // Format the period name
      final nextMonthName = DateFormat('MMMM yyyy').format(nextMonth);

      // Get the amount from the most recent period or use default
      double amount = defaultAmount ?? 1000.0; // Default amount if not specified

      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();

      periodsResult.fold(
        (failure) {
          // If we can't get existing periods, just use the default amount
        },
        (periods) {
          if (periods.isNotEmpty) {
            // Use the amount from the most recent period
            final mostRecentPeriod = periods.first;
            if (mostRecentPeriod.amount != null && mostRecentPeriod.amount! > 0) {
              amount = mostRecentPeriod.amount!;
            }
          }
        },
      );

      // Create the new period
      final result = await _maintenanceRepository.createMaintenancePeriod(
        name: nextMonthName,
        description: 'Automatically generated maintenance period for $nextMonthName',
        amount: amount,
        startDate: nextMonth,
        endDate: nextMonthEnd,
        dueDate: nextMonthDueDate,
      );

      return result.fold(
        (failure) => left(failure),
        (period) => right(period),
      );
    } catch (e, stackTrace) {
      return left(CustomFailure(
        message: 'Failed to create automatic maintenance period: $e',
        stackTrace: stackTrace,
      ));
    }
  }

  /// Check and create a new period if needed
  /// Returns the created period if one was created, null otherwise
  Future<EitherResult<MaintenancePeriodModel?>> checkAndCreatePeriod({
    double? defaultAmount,
  }) async {
    try {
      final shouldCreate = await shouldCreateNewPeriod();

      if (!shouldCreate) {
        return right(null); // No need to create a new period
      }

      // Create a new period for next month
      final result = await createNextMonthPeriod(defaultAmount: defaultAmount);

      return result;
    } catch (e, stackTrace) {
      return left(CustomFailure(
        message: 'Error in automatic maintenance period creation: $e',
        stackTrace: stackTrace,
      ));
    }
  }
}

import 'package:flutter/foundation.dart';
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
  /// Returns true if today is the 27th of the month and no period exists for current month
  Future<bool> shouldCreateNewPeriod() async {
    // Check if today is the 27th of the month
    final now = DateTime.now();
    if (now.day == 27) {
      // Continue with the check if it's the 27th
    } else {
      return false;
    }

    // Get all maintenance periods
    final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();

    return periodsResult.fold(
      (failure) => false, // If there's an error, don't create a new period
      (periods) {
        // Calculate current month's start date
        final currentMonth = DateTime(now.year, now.month, 1);
        final currentMonthName = DateFormat('MMMM yyyy').format(currentMonth);

        // Check if a period already exists for current month
        final existingPeriod = periods.any((period) =>
            period.name?.toLowerCase() == currentMonthName.toLowerCase() ||
            (period.startDate != null &&
                DateTime.parse(period.startDate!).month == currentMonth.month &&
                DateTime.parse(period.startDate!).year == currentMonth.year));

        // Return true if no period exists for current month
        return !existingPeriod;
      },
    );
  }

  /// Create a new maintenance period for the current month
  Future<EitherResult<MaintenancePeriodModel>> createCurrentMonthPeriod({
    double? defaultAmount,
  }) async {
    try {
      final now = DateTime.now();

      // Calculate current month's dates
      final currentMonth = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0); // Last day of current month
      final currentMonthDueDate = DateTime(now.year, now.month, 25); // Due on 25th of current month

      // Format the period name
      final currentMonthName = DateFormat('MMMM yyyy').format(currentMonth);

      // Check if a period already exists for the current month
      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();

      final existingPeriod = periodsResult.fold(
        (failure) => false, // If there's an error, assume no existing period
        (periods) {
          return periods.any((period) =>
              period.name?.toLowerCase() == currentMonthName.toLowerCase() ||
              (period.startDate != null &&
                  DateTime.parse(period.startDate!).month == currentMonth.month &&
                  DateTime.parse(period.startDate!).year == currentMonth.year));
        },
      );

      // If a period already exists for this month, don't create another one
      if (existingPeriod) {
        return left(CustomFailure(
          message: 'A maintenance period for $currentMonthName already exists',
        ));
      }

      // Get the amount from the most recent period or use default
      double amount = defaultAmount ?? 1000.0; // Default amount if not specified

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
        name: currentMonthName,
        description: 'Automatically generated maintenance period for $currentMonthName',
        amount: amount,
        startDate: currentMonth,
        endDate: currentMonthEnd,
        dueDate: currentMonthDueDate,
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
        // Even if it's not the 27th, check if we missed creating a period
        return await checkForMissedPeriods(defaultAmount: defaultAmount);
      }

      // Create a new period for current month
      final result = await createCurrentMonthPeriod(defaultAmount: defaultAmount);

      if (result.isRight()) {
        _logPeriodCreation(result);
      }

      return result;
    } catch (e, stackTrace) {
      return left(CustomFailure(
        message: 'Error in automatic maintenance period creation: $e',
        stackTrace: stackTrace,
      ));
    }
  }

  /// Check if we missed creating periods for any months
  /// This ensures periods are created even if the app wasn't running on the 27th
  Future<EitherResult<MaintenancePeriodModel?>> checkForMissedPeriods({
    double? defaultAmount,
  }) async {
    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      // Get all maintenance periods
      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();

      return periodsResult.fold(
        (failure) => right(null), // If there's an error, don't create a period
        (periods) async {
          // Check if a period exists for the current month
          final currentMonthName = DateFormat('MMMM yyyy').format(currentMonth);
          final hasCurrentMonth = periods.any((period) =>
              period.name?.toLowerCase() == currentMonthName.toLowerCase() ||
              (period.startDate != null &&
                  DateTime.parse(period.startDate!).month == currentMonth.month &&
                  DateTime.parse(period.startDate!).year == currentMonth.year));

          // If we're on or past the 27th and don't have a period for current month, create it
          if (now.day >= 27 && !hasCurrentMonth) {
            // Create a period for the current month
            final result = await createPeriodForMonth(
              targetMonth: currentMonth,
              defaultAmount: defaultAmount,
            );

            if (result.isRight()) {
              _logPeriodCreation(result, wasMissed: true);
            }

            return result;
          }

          return right(null); // No missed periods to create
        },
      );
    } catch (e, stackTrace) {
      return left(CustomFailure(
        message: 'Error checking for missed maintenance periods: $e',
        stackTrace: stackTrace,
      ));
    }
  }

  /// Create a maintenance period for a specific month
  Future<EitherResult<MaintenancePeriodModel>> createPeriodForMonth({
    required DateTime targetMonth,
    double? defaultAmount,
  }) async {
    try {
      // Calculate month dates
      final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
      final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0); // Last day of month
      final monthDueDate = DateTime(targetMonth.year, targetMonth.month, 25); // Due on 25th

      // Format the period name
      final monthName = DateFormat('MMMM yyyy').format(monthStart);

      // Check if a period already exists for this month
      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();

      final existingPeriod = periodsResult.fold(
        (failure) => false, // If there's an error, assume no existing period
        (periods) {
          return periods.any((period) =>
              period.name?.toLowerCase() == monthName.toLowerCase() ||
              (period.startDate != null &&
                  DateTime.parse(period.startDate!).month == monthStart.month &&
                  DateTime.parse(period.startDate!).year == monthStart.year));
        },
      );

      // If a period already exists for this month, don't create another one
      if (existingPeriod) {
        return left(CustomFailure(
          message: 'A maintenance period for $monthName already exists',
        ));
      }

      // Get the amount from the most recent period or use default
      double amount = defaultAmount ?? 1000.0; // Default amount if not specified

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
        name: monthName,
        description: 'Automatically generated maintenance period for $monthName',
        amount: amount,
        startDate: monthStart,
        endDate: monthEnd,
        dueDate: monthDueDate,
      );

      return result.fold(
        (failure) => left(failure),
        (period) => right(period),
      );
    } catch (e, stackTrace) {
      return left(CustomFailure(
        message: 'Failed to create maintenance period for specific month: $e',
        stackTrace: stackTrace,
      ));
    }
  }

  /// Log period creation for debugging
  void _logPeriodCreation(EitherResult<MaintenancePeriodModel?> result, {bool wasMissed = false}) {
    result.fold(
      (failure) => null,
      (period) {
        if (period != null && kDebugMode) {
          final source = wasMissed ? 'missed period recovery' : 'scheduled creation';
          print('AUTO-MAINTENANCE: Created period ${period.name} via $source');
        }
      },
    );
  }
}

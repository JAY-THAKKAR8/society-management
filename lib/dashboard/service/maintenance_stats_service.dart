import 'package:fpdart/fpdart.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/utility/app_typednfs.dart';

class MaintenanceStatsService {
  final IMaintenanceRepository _maintenanceRepository;

  MaintenanceStatsService({IMaintenanceRepository? maintenanceRepository})
      : _maintenanceRepository = maintenanceRepository ?? getIt<IMaintenanceRepository>();

  /// Get the most recent active maintenance period
  Future<EitherResult<MaintenancePeriodModel?>> getLatestActivePeriod() async {
    final periodsResult = await _maintenanceRepository.getActiveMaintenancePeriods();

    return periodsResult.fold(
      (failure) => left(failure),
      (periods) {
        if (periods.isEmpty) {
          return right(null);
        }

        // Sort by start date (most recent first)
        periods.sort((a, b) {
          if (a.startDate == null) return 1;
          if (b.startDate == null) return -1;
          return DateTime.parse(b.startDate!).compareTo(DateTime.parse(a.startDate!));
        });

        return right(periods.first);
      },
    );
  }
}

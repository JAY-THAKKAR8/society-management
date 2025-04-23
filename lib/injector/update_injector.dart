import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/repository/maintenance_repository.dart';
import 'package:society_management/injector/injector.dart';

void updateInjector() {
  // Register the maintenance repository
  getIt.registerFactory<IMaintenanceRepository>(
    () => MaintenanceRepository(getIt()),
  );
}

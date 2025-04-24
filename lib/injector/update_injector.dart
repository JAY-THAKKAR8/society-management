import 'package:society_management/complaints/repository/complaint_repository.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/repository/maintenance_repository.dart';

void updateInjector() {
  // Register the maintenance repository
  getIt.registerFactory<IMaintenanceRepository>(
    () => MaintenanceRepository(getIt()),
  );

  // Register the complaint repository
  getIt.registerFactory<IComplaintRepository>(
    () => ComplaintRepository(getIt()),
  );
}

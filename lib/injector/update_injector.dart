import 'package:society_management/complaints/repository/complaint_repository.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/events/repository/event_repository.dart';
import 'package:society_management/events/repository/event_repository_interface.dart';
import 'package:society_management/events/service/event_service.dart';
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

  // Register the event repository
  getIt.registerFactory<IEventRepository>(
    () => EventRepository(firestore: getIt()),
  );

  // Register the event service
  getIt.registerFactory<EventService>(
    () => EventService(),
  );
}

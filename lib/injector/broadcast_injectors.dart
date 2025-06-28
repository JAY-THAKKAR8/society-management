import 'package:injectable/injectable.dart';
import 'package:society_management/broadcasting/repository/broadcast_repository.dart';
import 'package:society_management/broadcasting/repository/i_broadcast_repository.dart';
import 'package:society_management/broadcasting/service/broadcast_service.dart';

@module
abstract class BroadcastInjectableModule {
  @lazySingleton
  IBroadcastRepository get broadcastRepository => BroadcastRepository();

  @lazySingleton
  BroadcastService broadcastService(IBroadcastRepository repository) => BroadcastService(repository);
}

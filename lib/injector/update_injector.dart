import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/chat/repository/chat_repository.dart';
import 'package:society_management/chat/service/ai_service.dart';
import 'package:society_management/chat/service/gemini_service.dart';
import 'package:society_management/chat/service/mock_ai_service.dart';
import 'package:society_management/complaints/repository/complaint_repository.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/events/repository/event_repository.dart';
import 'package:society_management/events/repository/event_repository_interface.dart';
import 'package:society_management/events/service/event_service.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/repository/maintenance_repository.dart';

void updateInjector() {
  // Register the AuthService
  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerSingleton<AuthService>(
      AuthService(),
    );
  }

  // Register the maintenance repository
  if (!getIt.isRegistered<IMaintenanceRepository>()) {
    getIt.registerFactory<IMaintenanceRepository>(
      () => MaintenanceRepository(getIt()),
    );
  }

  // Register the complaint repository
  if (!getIt.isRegistered<IComplaintRepository>()) {
    getIt.registerFactory<IComplaintRepository>(
      () => ComplaintRepository(getIt()),
    );
  }

  // Register the event repository
  if (!getIt.isRegistered<IEventRepository>()) {
    getIt.registerFactory<IEventRepository>(
      () => EventRepository(firestore: getIt()),
    );
  }

  // Register the event service
  if (!getIt.isRegistered<EventService>()) {
    getIt.registerFactory<EventService>(
      () => EventService(),
    );
  }

  // Register the chat repository
  if (!getIt.isRegistered<IChatRepository>()) {
    getIt.registerSingleton<IChatRepository>(
      ChatRepository(),
    );
  }

  // Register the AI service
  if (!getIt.isRegistered<AIService>()) {
    // Set to true to use Gemini, false to use Mock service
    const bool useGemini = true;

    if (useGemini) {
      // Use Gemini service (requires API key)
      getIt.registerSingleton<AIService>(
        GeminiService(),
      );
    } else {
      // Use Mock service (no API key needed)
      getIt.registerSingleton<AIService>(
        MockAIService(),
      );
    }
  }
}

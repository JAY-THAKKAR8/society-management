import 'package:injectable/injectable.dart';
import 'package:society_management/chat/repository/chat_repository.dart';
import 'package:society_management/chat/service/ai_service.dart';

@module
abstract class ChatModule {
  @singleton
  IChatRepository get chatRepository => ChatRepository();

  @singleton
  AIService get aiService => AIService();
}

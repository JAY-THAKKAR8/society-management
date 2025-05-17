import 'package:society_management/config/api_keys.dart';

class ChatConfig {
  // OpenAI API key from api_keys.dart
  static const String openAIApiKey = ApiKeys.openAIApiKey;

  // OpenAI API endpoint
  static const String openAIEndpoint = 'https://api.openai.com/v1/chat/completions';

  // Model to use
  static const String model = 'gpt-3.5-turbo';

  // System prompt for the AI assistant
  static const String systemPrompt = 'You are a helpful assistant for a Society Management app. '
      'You help users with questions about maintenance payments, '
      'society events, complaints, and other features of the app. '
      'Keep your answers concise, friendly, and focused on society management topics.';
}

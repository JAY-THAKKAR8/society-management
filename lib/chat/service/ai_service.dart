/// Base class for AI services.
/// This class is meant to be extended by concrete implementations like GeminiService.
class AIService {
  /// Generates a response to the given prompt.
  /// This method should be overridden by subclasses.
  Future<String> generateResponse(String prompt) async {
    // This is a base implementation that should be overridden.
    // If this method is called directly, it means no concrete implementation was provided.
    return "AI service not properly configured. Please check your setup.";
  }
}

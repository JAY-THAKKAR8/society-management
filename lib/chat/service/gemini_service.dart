import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:society_management/chat/config/gemini_config.dart';
import 'package:society_management/chat/service/ai_service.dart';
import 'package:society_management/chat/service/society_data_service.dart';

/// A service that uses Google's Gemini API to generate responses.
class GeminiService extends AIService {
  final String _apiKey = GeminiConfig.apiKey;
  final SocietyDataService _dataService = SocietyDataService();

  @override
  Future<String> generateResponse(String prompt) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'your_gemini_api_key_here') {
        return "API key not configured. Please set your Google Gemini API key in the GeminiConfig file.";
      }

      // Check if the prompt is asking for society-specific information
      final bool needsSocietyData = _promptNeedsSocietyData(prompt);
      String enhancedPrompt = prompt;

      // If the prompt is asking about society data, fetch it and enhance the prompt
      if (needsSocietyData) {
        try {
          final societyData = await _dataService.getAllSocietyData();
          final dataJson = jsonEncode(societyData);

          enhancedPrompt = '''
I need information about our society. Here is the current data from our database:
$dataJson

Based on this data, please answer my question: $prompt
''';

          debugPrint('Enhanced prompt with society data');
        } catch (e) {
          debugPrint('Error enhancing prompt with society data: $e');
          // Continue with original prompt if there's an error
        }
      }

      // Construct the API URL with the API key
      final url = '${GeminiConfig.apiEndpoint}?key=$_apiKey';

      debugPrint('Using Gemini API URL: $url');

      // Prepare the request body for the Gemini 2.0 Flash API
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': '${GeminiConfig.systemPrompt}\n\n$enhancedPrompt'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      };

      // Make the API request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          debugPrint('Response data: ${response.body}');

          // Extract the response text from the Gemini API response
          if (data.containsKey('candidates') &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0].containsKey('content') &&
              data['candidates'][0]['content'].containsKey('parts') &&
              data['candidates'][0]['content']['parts'].isNotEmpty &&
              data['candidates'][0]['content']['parts'][0].containsKey('text')) {
            // Standard Gemini API format
            final responseText = data['candidates'][0]['content']['parts'][0]['text'];
            return responseText;
          } else if (data.containsKey('candidates') &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0].containsKey('text')) {
            // Alternative format
            return data['candidates'][0]['text'];
          } else if (data.containsKey('content') &&
              data['content'].containsKey('parts') &&
              data['content']['parts'].isNotEmpty &&
              data['content']['parts'][0].containsKey('text')) {
            // New Gemini API format
            return data['content']['parts'][0]['text'];
          }

          debugPrint('Unexpected response format: ${response.body}');
          return "I received a response but couldn't understand it. Please try again.";
        } catch (e) {
          debugPrint('Error parsing response: $e, Body: ${response.body}');
          return "I received a response but couldn't process it correctly. Please try again.";
        }
      } else {
        debugPrint('Error: ${response.statusCode}, ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          final errorStatus = errorData['error']?['status'] ?? 'UNKNOWN';

          debugPrint('Detailed error: $errorStatus - $errorMessage');

          return "Sorry, I couldn't generate a response. Error: $errorStatus - $errorMessage";
        } catch (e) {
          return "Sorry, I couldn't generate a response at the moment. Please try again later. (Error ${response.statusCode})";
        }
      }
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      return "Sorry, an error occurred while processing your request. Please try again later.";
    }
  }

  /// Determines if the prompt is asking for society-specific information
  bool _promptNeedsSocietyData(String prompt) {
    // Convert prompt to lowercase for case-insensitive matching
    final lowerPrompt = prompt.toLowerCase();

    // List of keywords that indicate the user is asking about society data
    final societyKeywords = [
      'society',
      'maintenance',
      'payment',
      'due',
      'pending',
      'paid',
      'amount',
      'total',
      'statistics',
      'stats',
      'members',
      'users',
      'line',
      'villa',
      'expenses',
      'collection',
      'collected',
      'how much',
      'when is',
      'who has',
      'who is',
      'how many',
      'my name',
      'my role',
      'my line',
      'my villa',
      'my payment',
      'my maintenance',
      'my dues',
      'my status',
      'my information',
      'user info',
      'user information',
      'profile',
      'details',
      'show me',
      'tell me about',
      'what is my',
      'what are my',
      'financial',
      'money',
      'balance',
      'account',
      'status',
      'period',
      'active',
      'current',
      'month',
      'date',
      'deadline',
      'overdue',
      'late',
      'fee',
      'penalty',
      'charge'
    ];

    // Check if any of the keywords are in the prompt
    for (final keyword in societyKeywords) {
      if (lowerPrompt.contains(keyword)) {
        return true;
      }
    }

    return false;
  }
}

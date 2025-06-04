import 'package:flutter/material.dart';
import 'package:society_management/chat/config/gemini_config.dart';
import 'package:society_management/chat/service/gemini_service.dart';
import 'package:society_management/config/api_keys.dart';
import 'package:society_management/constants/app_colors.dart';

/// A simple widget to test the Gemini API connection with Firebase
class GeminiApiTestPage extends StatefulWidget {
  const GeminiApiTestPage({super.key});

  @override
  State<GeminiApiTestPage> createState() => _GeminiApiTestPageState();
}

class _GeminiApiTestPageState extends State<GeminiApiTestPage> {
  final TextEditingController _promptController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  String _response = '';
  bool _isLoading = false;
  String _apiKeyStatus = '';

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  void _checkApiKey() {
    const apiKey = ApiKeys.geminiApiKey;
    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      setState(() {
        _apiKeyStatus = 'API Key not configured properly';
      });
    } else {
      setState(() {
        _apiKeyStatus = 'Using API Key: ${apiKey.substring(0, 5)}...${apiKey.substring(apiKey.length - 4)}';
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _testGeminiApi() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response = await _geminiService.generateResponse(_promptController.text);
      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key status card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase + Gemini API Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('API Key Status: $_apiKeyStatus'),
                    const SizedBox(height: 4),
                    const Text('API Endpoint: ${GeminiConfig.apiEndpoint}'),
                    const SizedBox(height: 4),
                    const Text('Model: ${GeminiConfig.model}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter your prompt',
                border: OutlineInputBorder(),
                hintText: 'Example: Tell me about society maintenance payments',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGeminiApi,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Test Gemini API'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Response:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_response),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

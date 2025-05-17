import 'package:flutter/material.dart';
import 'package:society_management/bootstrap.dart';
import 'package:society_management/chat/test/gemini_api_test_fixed.dart';

/// This is a special entry point for testing the Gemini API connection
/// Run this file directly to test the Gemini API without going through the normal app flow
void main() {
  // Bootstrap the app with our test page
  bootstrap(const GeminiTestApp());
}

/// A simple app that directly shows the Gemini API test page
class GeminiTestApp extends StatelessWidget {
  const GeminiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini API Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GeminiApiTestPage(),
    );
  }
}

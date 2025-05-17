import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service to handle voice input and output for the chat
class VoiceChatService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  String _lastError = '';

  // Callbacks
  Function(String)? onSpeechResult;
  VoidCallback? onSpeechStart;
  VoidCallback? onSpeechEnd;
  Function(String)? onSpeechError;
  VoidCallback? onTtsStart;
  VoidCallback? onTtsEnd;

  /// Initialize the speech recognition and text-to-speech services
  Future<bool> initialize() async {
    try {
      // Initialize text to speech first (usually more reliable)
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        if (onTtsStart != null) onTtsStart!();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        if (onTtsEnd != null) onTtsEnd!();
      });

      _flutterTts.setErrorHandler((error) {
        _isSpeaking = false;
        debugPrint("TTS Error: $error");
        if (onTtsEnd != null) onTtsEnd!();
      });

      // Initialize speech to text with multiple attempts
      bool hasSpeechPermission = await _speechToText.hasPermission;
      if (!hasSpeechPermission) {
        debugPrint("Requesting speech permission");
      }

      // First attempt with default settings
      _speechEnabled = await _speechToText.initialize(
        onError: _onSpeechError,
        debugLogging: true,
      );

      // If first attempt fails, try again with a delay
      if (!_speechEnabled) {
        debugPrint("First initialization attempt failed, trying again after delay");
        try {
          // Wait a bit and try again
          await Future.delayed(const Duration(milliseconds: 500));
          _speechEnabled = await _speechToText.initialize(
            onError: _onSpeechError,
            debugLogging: true,
          );
        } catch (e) {
          debugPrint("Second initialization attempt failed: $e");
        }
      }

      if (_speechEnabled) {
        debugPrint("Speech recognition initialized successfully");
        // Get available locales and log them
        try {
          final locales = await _speechToText.locales();
          debugPrint("Available locales: ${locales.map((e) => e.localeId).join(', ')}");
        } catch (e) {
          debugPrint("Error getting locales: $e");
        }
      } else {
        debugPrint("Failed to initialize speech recognition after multiple attempts");
        _lastError = "Speech recognition not available on this device. Please check your microphone permissions.";
      }

      return _speechEnabled;
    } catch (e) {
      _lastError = e.toString();
      debugPrint("Error initializing voice services: $e");
      return false;
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint("Speech recognition error: ${error.errorMsg} (${error.permanent})");
    _lastError = error.errorMsg;
    if (onSpeechError != null) {
      onSpeechError!(error.errorMsg);
    }
    _isListening = false;
    if (onSpeechEnd != null) onSpeechEnd!();
  }

  /// Start listening for speech input
  Future<bool> startListening() async {
    // If speech is not enabled, try to initialize it again
    if (!_speechEnabled) {
      debugPrint("Speech not enabled, trying to initialize again");
      _speechEnabled = await initialize();

      if (!_speechEnabled) {
        _lastError = "Speech recognition not available on this device. Please check your microphone permissions.";
        if (onSpeechError != null) onSpeechError!(_lastError);
        return false;
      }
    }

    // Check if we have permission
    if (!await _speechToText.hasPermission) {
      debugPrint("No speech permission, requesting it");
      try {
        // The speech_to_text package doesn't have a requestPermission method
        // We need to reinitialize to request permission
        _speechEnabled = await _speechToText.initialize(
          onError: _onSpeechError,
          debugLogging: true,
        );

        if (!_speechEnabled) {
          _lastError = "Speech recognition permission denied";
          if (onSpeechError != null) onSpeechError!(_lastError);
          return false;
        }
      } catch (e) {
        _lastError = "Error requesting speech permission: $e";
        if (onSpeechError != null) onSpeechError!(_lastError);
        return false;
      }
    }

    try {
      // If we're already listening, stop first
      if (_isListening) {
        stopListening();
        // Small delay to ensure previous session is fully stopped
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _isListening = true;

      // Try with different listen modes if one fails
      bool listenStarted = false;

      try {
        await _speechToText.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          localeId: "en_US",
          onSoundLevelChange: (level) {
            // Can be used to show sound level visualization
          },
          listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: false, // Don't cancel on error to be more resilient
            listenMode: ListenMode.confirmation,
          ),
        );
        listenStarted = true;
      } catch (e) {
        debugPrint("First listen attempt failed: $e");

        // Try with dictation mode if confirmation mode fails
        if (!listenStarted) {
          try {
            await _speechToText.listen(
              onResult: _onSpeechResult,
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 5),
              localeId: "en_US",
              onSoundLevelChange: (level) {
                // Can be used to show sound level visualization
              },
              listenOptions: SpeechListenOptions(
                partialResults: true,
                cancelOnError: false,
                listenMode: ListenMode.dictation,
              ),
            );
            listenStarted = true;
          } catch (e) {
            debugPrint("Second listen attempt failed: $e");
          }
        }
      }

      if (!listenStarted) {
        throw Exception("Failed to start speech recognition after multiple attempts");
      }

      if (onSpeechStart != null) onSpeechStart!();
      return true;
    } catch (e) {
      _lastError = "Error starting speech recognition: $e";
      debugPrint(_lastError);
      _isListening = false;
      if (onSpeechError != null) onSpeechError!(_lastError);
      return false;
    }
  }

  /// Get the last error message
  String getLastError() {
    return _lastError;
  }

  /// Stop listening for speech input
  void stopListening() {
    _speechToText.stop();
    _isListening = false;
    if (onSpeechEnd != null) onSpeechEnd!();
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult && onSpeechResult != null) {
      onSpeechResult!(result.recognizedWords);
      _isListening = false;
      if (onSpeechEnd != null) onSpeechEnd!();
    }
  }

  /// Speak the given text
  Future<bool> speak(String text) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      // Check if TTS is available
      final voices = await _flutterTts.getVoices;
      if (voices == null || (voices is List && voices.isEmpty)) {
        _lastError = "Text-to-speech not available on this device";
        debugPrint(_lastError);
        return false;
      }

      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      _lastError = "Error with text-to-speech: $e";
      debugPrint(_lastError);
      return false;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  /// Check if speech recognition is currently active
  bool get isListening => _isListening;

  /// Check if text-to-speech is currently active
  bool get isSpeaking => _isSpeaking;

  /// Check if speech recognition is available
  bool get isSpeechEnabled => _speechEnabled;

  /// Dispose of resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}

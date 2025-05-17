import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:society_management/chat/service/voice_chat_service.dart';
import 'package:society_management/utility/utility.dart';

class VoiceInputPage extends StatefulWidget {
  final VoiceChatService voiceChatService;

  const VoiceInputPage({
    super.key,
    required this.voiceChatService,
  });

  @override
  State<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends State<VoiceInputPage> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _recognizedText = '';
  String _statusText = 'Tap to speak';
  bool _showManualInput = false;
  final TextEditingController _textController = TextEditingController();

  // Animation controller for the voice visualization
  late AnimationController _animationController;
  final List<double> _soundLevels = List.filled(8, 0.0);
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Set up callbacks
    widget.voiceChatService.onSpeechResult = _handleSpeechResult;
    widget.voiceChatService.onSpeechStart = _handleSpeechStart;
    widget.voiceChatService.onSpeechEnd = _handleSpeechEnd;
    widget.voiceChatService.onSpeechError = _handleSpeechError;

    // Start listening automatically when the page opens
    _startListening();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSpeechResult(String text) {
    setState(() {
      _recognizedText = text;
      if (text.isNotEmpty) {
        _statusText = 'Listening...';
      }
    });
  }

  void _handleSpeechStart() {
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });

    // Start the animation for sound levels
    _startSoundLevelAnimation();
  }

  void _handleSpeechEnd() {
    setState(() {
      _isListening = false;
      _statusText = 'Tap to speak again';
    });

    // Stop the animation
    _animationTimer?.cancel();

    // If we have recognized text, return it to the chat page
    if (_recognizedText.isNotEmpty) {
      Navigator.pop(context, _recognizedText);
    }
  }

  void _handleSpeechError(String errorMsg) {
    setState(() {
      _isListening = false;
      _statusText = 'Error: $errorMsg';
    });

    // Stop the animation
    _animationTimer?.cancel();

    // Show error toast
    Utility.toast(message: errorMsg);

    // If it's a permission error, show a more helpful message and manual input option
    if (errorMsg.contains("permission") || errorMsg.contains("not available")) {
      setState(() {
        _statusText = 'Please check your microphone permissions in device settings';
        _showManualInput = true; // Show manual input option
      });

      // Don't automatically pop back for permission errors
      // Let the user read the message and manually input text
    } else {
      // For other errors, wait a moment and then pop back to chat page
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _startSoundLevelAnimation() {
    // Cancel any existing timer
    _animationTimer?.cancel();

    // Create a timer that updates the sound levels
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _isListening) {
        setState(() {
          // Simulate sound levels with random values
          for (int i = 0; i < _soundLevels.length; i++) {
            _soundLevels[i] =
                (0.1 + 0.9 * (0.5 + 0.5 * math.sin(DateTime.now().millisecondsSinceEpoch / 300 + i * 0.5)));
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startListening() async {
    final success = await widget.voiceChatService.startListening();
    if (!success) {
      final errorMsg = widget.voiceChatService.getLastError();
      setState(() {
        _statusText = 'Error: $errorMsg';

        // Show manual input option if speech recognition fails
        if (errorMsg.contains("permission") || errorMsg.contains("not available")) {
          _showManualInput = true;
          _statusText = 'Please check your microphone permissions in device settings';
        }
      });

      // Show error toast
      Utility.toast(message: errorMsg);

      // Only pop back for non-permission errors
      if (!errorMsg.contains("permission") && !errorMsg.contains("not available")) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  void _toggleListening() {
    if (_isListening) {
      widget.voiceChatService.stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: UniqueKey(), // Add a unique key to prevent duplicate key issues
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: DropdownButton<String>(
          value: 'English',
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          underline: Container(),
          dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
          items: ['English', 'Hindi', 'Spanish'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            // Language selection logic would go here
          },
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _toggleListening,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Voice visualization
              Container(
                height: 80,
                width: 200,
                margin: const EdgeInsets.symmetric(vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _soundLevels.length,
                    (index) => _buildSoundBar(index),
                  ),
                ),
              ),

              // Status text
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 24,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              // Recognized text
              if (_recognizedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _recognizedText,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

              const Spacer(),

              // Manual text input (shown when speech recognition fails)
              if (_showManualInput)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message here...',
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.pop(context, text);
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // "Try typing instead" button when speech recognition fails
              if (_showManualInput)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextButton.icon(
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Try typing instead'),
                    onPressed: () {
                      setState(() {
                        _statusText = 'Type your message below';
                      });
                    },
                  ),
                ),

              // Microphone button at bottom
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleListening,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? const Color.fromRGBO(33, 150, 243, 0.2) : Colors.transparent,
                        border: Border.all(
                          color: _isListening ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 40,
                        color: _isListening ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundBar(int index) {
    final level = _soundLevels[index];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.yellow,
      Colors.green,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 8,
      height: 60 * level,
      decoration: BoxDecoration(
        color: colors[index],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

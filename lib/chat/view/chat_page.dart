import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/chat/model/chat_message_model.dart';
import 'package:society_management/chat/repository/chat_repository.dart';
import 'package:society_management/chat/service/ai_service.dart';
import 'package:society_management/chat/service/gemini_service.dart';
import 'package:society_management/chat/service/voice_chat_service.dart';
import 'package:society_management/chat/view/voice_input_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/utility.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final IChatRepository _chatRepository = getIt<IChatRepository>();
  final AIService _aiService = getIt<AIService>();
  final AuthService _authService = AuthService();
  final VoiceChatService _voiceChatService = VoiceChatService();
  final List<types.Message> _messages = [];
  final _uuid = const Uuid();
  late types.User _user;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    try {
      // Initialize voice service
      final speechEnabled = await _voiceChatService.initialize();

      // Set up callbacks
      _voiceChatService.onSpeechResult = (text) {
        setState(() {
          _textController.text = text;
        });
        // Auto-send the message when speech is done
        if (text.isNotEmpty) {
          _handleSendPressed(types.PartialText(text: text));
        }
      };

      _voiceChatService.onSpeechStart = () {
        setState(() {
          _isListening = true;
        });
      };

      _voiceChatService.onSpeechEnd = () {
        setState(() {
          _isListening = false;
        });
      };

      _voiceChatService.onSpeechError = (errorMsg) {
        setState(() {
          _isListening = false;
        });
        debugPrint("Speech error: $errorMsg");
      };

      _voiceChatService.onTtsStart = () {
        setState(() {
          _isSpeaking = true;
        });
      };

      _voiceChatService.onTtsEnd = () {
        setState(() {
          _isSpeaking = false;
        });
      };

      if (!speechEnabled) {
        debugPrint("Speech recognition initialization failed");
        // We'll show a toast when the user tries to use voice input
      }
    } catch (e) {
      debugPrint("Error initializing voice service: $e");
    }
  }

  @override
  void dispose() {
    _voiceChatService.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        Utility.toast(message: 'User not authenticated');
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      _user = types.User(
        id: currentUser.id!,
        firstName: currentUser.name,
      );

      await _loadMessages(currentUser.id!);
    } catch (e) {
      Utility.toast(message: 'Error initializing chat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages(String userId) async {
    try {
      final result = await _chatRepository.getChatHistory(userId);
      result.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (chatMessages) {
          final messages = chatMessages.map((chatMessage) {
            return types.TextMessage(
              author: types.User(
                id: chatMessage.sender == MessageSender.user ? _user.id : 'bot',
                firstName: chatMessage.sender == MessageSender.user ? _user.firstName : 'AI Assistant',
              ),
              id: chatMessage.id,
              text: chatMessage.text,
              createdAt: chatMessage.timestamp.millisecondsSinceEpoch,
            );
          }).toList();

          if (mounted) {
            setState(() {
              _messages.clear();
              _messages.addAll(messages);
            });
          }
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error loading messages: $e');
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Add user message to UI
      final userMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        text: message.text,
      );

      setState(() {
        _messages.insert(0, userMessage);
      });

      // Save user message to Firestore
      final userMessageResult = await _chatRepository.sendMessage(_user.id, message.text);

      userMessageResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (_) async {
          // Show typing indicator
          setState(() {
            _messages.insert(
              0,
              const types.CustomMessage(
                author: types.User(id: 'bot'),
                id: 'typing-indicator',
                metadata: {'isTyping': true},
              ),
            );
          });

          // Get AI response
          final aiResponse = await _aiService.generateResponse(message.text);

          // Remove typing indicator
          setState(() {
            _messages.removeWhere((element) => element.id == 'typing-indicator');
          });

          // Add AI response to UI
          final botMessage = types.TextMessage(
            author: const types.User(id: 'bot', firstName: 'AI Assistant'),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: _uuid.v4(),
            text: aiResponse,
          );

          setState(() {
            _messages.insert(0, botMessage);
          });

          // Speak the AI response
          _speakAIResponse(aiResponse);

          // Save AI response to Firestore
          await _chatRepository.saveAIResponse(_user.id, aiResponse);
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Always here to help',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : AppColors.lightText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
            tooltip: 'About AI Assistant',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading your assistant...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Welcome message if no messages
                  if (_messages.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: AppColors.primaryBlue,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'How can I help you today?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Ask me anything about maintenance payments, society events, complaints, or other features of the app.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildSuggestionChips(context),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Expanded(
                              child: Chat(
                                key: UniqueKey(), // Add a unique key to prevent duplicate key issues
                                messages: _messages,
                                onSendPressed: _handleSendPressed,
                                user: _user,
                                theme: DefaultChatTheme(
                                  backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
                                  primaryColor: AppColors.primaryBlue,
                                  secondaryColor: isDarkMode ? AppColors.darkCard : Colors.grey.shade200,
                                  inputBackgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
                                  inputTextColor: isDarkMode ? Colors.white : Colors.black87,
                                  sentMessageBodyTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  receivedMessageBodyTextStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                  inputTextStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                  inputTextCursorColor: AppColors.primaryBlue,
                                  inputBorderRadius: BorderRadius.circular(24),
                                  inputMargin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                  inputPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  sendButtonIcon: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  sendButtonMargin: const EdgeInsets.only(right: 12),
                                  sendingIcon: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                                customBottomWidget: Container(
                                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? AppColors.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(13),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Voice input button
                                      IconButton(
                                        icon: Icon(
                                          _isListening ? Icons.mic : Icons.mic_none,
                                          color: _isListening
                                              ? AppColors.primaryBlue
                                              : isDarkMode
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                        ),
                                        onPressed: _openVoiceInputPage,
                                        tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                                      ),
                                      // Text input field
                                      Expanded(
                                        child: TextField(
                                          controller: _textController,
                                          decoration: InputDecoration(
                                            hintText: _isListening ? 'Listening...' : 'Type your message here...',
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(
                                              color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                          onSubmitted: (text) {
                                            if (text.isNotEmpty) {
                                              _handleSendPressed(types.PartialText(text: text));
                                              _textController.clear();
                                            }
                                          },
                                        ),
                                      ),
                                      // Send button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          color: AppColors.primaryBlue,
                                        ),
                                        onPressed: () {
                                          final text = _textController.text.trim();
                                          if (text.isNotEmpty) {
                                            _handleSendPressed(types.PartialText(text: text));
                                            _textController.clear();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                customMessageBuilder: (message, {required messageWidth}) {
                                  if (message.metadata?['isTyping'] == true) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? AppColors.darkCard : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(13),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'AI is thinking...',
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                bubbleBuilder: (
                                  Widget child, {
                                  required message,
                                  required nextMessageInGroup,
                                }) {
                                  // Only add voice button to AI messages
                                  if (message.author.id == 'bot' && message is types.TextMessage) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        child,
                                        // Add a speak button to AI messages
                                        if (!nextMessageInGroup)
                                          Positioned(
                                            bottom: -10,
                                            right: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isDarkMode ? AppColors.darkCard : Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withAlpha(13),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                                  size: 20,
                                                  color: _isSpeaking
                                                      ? AppColors.primaryBlue
                                                      : isDarkMode
                                                          ? Colors.white70
                                                          : Colors.grey.shade700,
                                                ),
                                                onPressed: () => _speakAIResponse(message.text),
                                                tooltip: 'Listen to response',
                                                constraints: const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                                padding: const EdgeInsets.all(8),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }
                                  return child;
                                },
                                emptyState: Center(
                                  child: Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuggestionChips(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final suggestions = [
      'How do I pay maintenance?',
      'How to submit a complaint?',
      'Show upcoming events',
      'What can you help with?',
      'What is my pending amount?',
      'Show my user information',
      'What are the society statistics?',
      'When is my maintenance due?',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightContainerHighlight,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.lightText,
          ),
          side: BorderSide(
            color: isDarkMode ? Colors.transparent : AppColors.primaryBlue.withAlpha(51),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: () {
            final message = types.PartialText(text: suggestion);
            _handleSendPressed(message);
          },
        );
      }).toList(),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AI Assistant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your personal AI assistant for the Society Management app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('You can ask about:'),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Your personal information'),
                  Text('• Your pending maintenance payments'),
                  Text('• Society statistics and financial data'),
                  Text('• Maintenance periods and due dates'),
                  Text('• Society events and activities'),
                  Text('• Complaints and their status'),
                  Text('• App features and how to use them'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Get a Google Gemini API Key:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Go to Google AI Studio (makersuite.google.com)',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '2. Sign in with your Google account',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '3. Click "Get API key" or "Create API key"',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '4. Update the key in GeminiConfig.dart',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Currently using: ${_getAIServiceType()}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getAIServiceType() {
    final aiService = getIt<AIService>();
    if (aiService is GeminiService) {
      return 'Google Gemini AI (Active)';
    } else {
      return 'Mock AI (Demo Mode)';
    }
  }

  /// Speak the AI response using text-to-speech
  Future<void> _speakAIResponse(String text) async {
    // Don't speak if already speaking
    if (_isSpeaking) {
      await _voiceChatService.stopSpeaking();
    }

    // Clean up the text for better speech
    final cleanText = text
        .replaceAll(RegExp(r'\*\*.*?\*\*'), '') // Remove markdown bold
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '') // Remove markdown links
        .replaceAll(RegExp(r'```.*?```', dotAll: true), '') // Remove code blocks
        .replaceAll(RegExp(r'`.*?`'), '') // Remove inline code
        .replaceAll('\n', ' ') // Replace newlines with spaces
        .replaceAll('  ', ' '); // Replace double spaces with single spaces

    // Speak the text
    final success = await _voiceChatService.speak(cleanText);
    if (!success) {
      // Show a toast only the first time TTS fails
      final errorMsg = _voiceChatService.getLastError();
      if (errorMsg.contains("not available")) {
        Utility.toast(message: 'Text-to-speech not available on this device');
      }
    }
  }

  /// Open the voice input page
  Future<void> _openVoiceInputPage() async {
    // Stop any ongoing listening
    if (_isListening) {
      _voiceChatService.stopListening();
    }

    // Reset callbacks to avoid duplicate callbacks
    _voiceChatService.onSpeechResult = null;
    _voiceChatService.onSpeechStart = null;
    _voiceChatService.onSpeechEnd = null;
    _voiceChatService.onSpeechError = null;

    // Navigate to the voice input page
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceInputPage(
          key: UniqueKey(), // Add a unique key
          voiceChatService: _voiceChatService,
        ),
      ),
    );

    // Restore callbacks after returning from VoiceInputPage
    _voiceChatService.onSpeechResult = (text) {
      setState(() {
        _textController.text = text;
      });
      // Auto-send the message when speech is done
      if (text.isNotEmpty) {
        _handleSendPressed(types.PartialText(text: text));
      }
    };

    _voiceChatService.onSpeechStart = () {
      setState(() {
        _isListening = true;
      });
    };

    _voiceChatService.onSpeechEnd = () {
      setState(() {
        _isListening = false;
      });
    };

    _voiceChatService.onSpeechError = (errorMsg) {
      setState(() {
        _isListening = false;
      });
      debugPrint("Speech error: $errorMsg");
    };

    // If we got a result, send it as a message
    if (result != null && result.isNotEmpty) {
      _handleSendPressed(types.PartialText(text: result));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:society_management/chat/view/chat_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class ChatFAB extends StatelessWidget {
  const ChatFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        context.push(const ChatPage());
      },
      backgroundColor: AppColors.primaryBlue,
      tooltip: 'AI Assistant',
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }
}

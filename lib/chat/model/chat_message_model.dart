import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender {
  user,
  bot,
}

class ChatMessageModel {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String userId;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.userId,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      text: data['text'] ?? '',
      sender: data['sender'] == 'user' ? MessageSender.user : MessageSender.bot,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'sender': sender == MessageSender.user ? 'user' : 'bot',
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
    };
  }
}

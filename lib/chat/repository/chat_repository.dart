import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:society_management/chat/model/chat_message_model.dart';
import 'package:society_management/utility/failure.dart';
import 'package:uuid/uuid.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<ChatMessageModel>>> getChatHistory(String userId);
  Future<Either<Failure, ChatMessageModel>> sendMessage(String userId, String message);
  Future<Either<Failure, ChatMessageModel>> saveAIResponse(String userId, String message);
}

class ChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<ChatMessageModel>>> getChatHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();

      // Sort messages by timestamp (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return right(messages);
    } catch (e) {
      return left(Failure('Failed to get chat history: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageModel>> sendMessage(String userId, String message) async {
    try {
      final chatMessage = ChatMessageModel(
        id: _uuid.v4(),
        text: message,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        userId: userId,
      );

      await _firestore
          .collection('chats')
          .doc(chatMessage.id)
          .set(chatMessage.toFirestore());

      return right(chatMessage);
    } catch (e) {
      return left(Failure('Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageModel>> saveAIResponse(String userId, String message) async {
    try {
      final chatMessage = ChatMessageModel(
        id: _uuid.v4(),
        text: message,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        userId: userId,
      );

      await _firestore
          .collection('chats')
          .doc(chatMessage.id)
          .set(chatMessage.toFirestore());

      return right(chatMessage);
    } catch (e) {
      return left(Failure('Failed to save AI response: $e'));
    }
  }
}

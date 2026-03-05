import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chat_preview.dart';
import '../services/message_encryption_service.dart';

class ChatRepository {
  ChatRepository({
    FirebaseDatabase? firebaseDatabase,
    MessageEncryptionService? messageEncryptionService,
  }) : _database = (firebaseDatabase ?? FirebaseDatabase.instance).ref(),
       _messageEncryptionService =
           messageEncryptionService ?? MessageEncryptionService();

  final DatabaseReference _database;
  final MessageEncryptionService _messageEncryptionService;

  String buildChatRoomId(String firstUserId, String secondUserId) {
    return firstUserId.compareTo(secondUserId) > 0
        ? '${secondUserId}_$firstUserId'
        : '${firstUserId}_$secondUserId';
  }

  Stream<List<ChatPreview>> watchUserChats(String userId) {
    return _database
        .child('userChats/$userId')
        .orderByChild('updatedAt')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <ChatPreview>[];
          }

          final value = event.snapshot.value as Map<dynamic, dynamic>;
          final chats = value.entries
              .map((entry) {
                final chat = Map<dynamic, dynamic>.from(
                  entry.value as Map<dynamic, dynamic>,
                );
                chat['lastMessage'] = _readableText(chat['lastMessage']);
                return ChatPreview.fromMap(entry.key.toString(), chat);
              })
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return chats;
        });
  }

  Stream<List<ChatMessage>> watchMessages(String chatRoomId) {
    return _database
        .child('messages/$chatRoomId')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <ChatMessage>[];
          }

          final value = event.snapshot.value as Map<dynamic, dynamic>;
          final messages = value.entries
              .map((entry) {
                final message = Map<dynamic, dynamic>.from(
                  entry.value as Map<dynamic, dynamic>,
                );
                message['text'] = _readableText(message['text']);
                return ChatMessage.fromMap(entry.key.toString(), message);
              })
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  Future<void> ensureChatRoom({
    required String chatRoomId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    await _database.child('chats/$chatRoomId').update({
      'participants/$currentUserId': true,
      'participants/$otherUserId': true,
      'updatedAt': ServerValue.timestamp,
    });

    await _database.child('userChats/$currentUserId/$chatRoomId').set({
      'chatId': chatRoomId,
      'otherUserId': otherUserId,
      'updatedAt': ServerValue.timestamp,
    });

    await _database.child('userChats/$otherUserId/$chatRoomId').set({
      'chatId': chatRoomId,
      'otherUserId': currentUserId,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final encryptedText = _messageEncryptionService.encryptText(text);
    if (!_messageEncryptionService.isEncryptedPayload(encryptedText)) {
      throw StateError('Message encryption failed. Plaintext write blocked.');
    }
    debugPrint('Encrypted chat payload prepared: $encryptedText');

    await _database.child('messages/$chatRoomId').push().set({
      'senderId': senderId,
      'text': encryptedText,
      'isEncrypted': true,
      'createdAt': ServerValue.timestamp,
    });

    await _database.child('chats/$chatRoomId').update({
      'lastMessage': encryptedText,
      'updatedAt': ServerValue.timestamp,
    });

    await _database.child('userChats/$senderId/$chatRoomId').update({
      'lastMessage': encryptedText,
      'updatedAt': ServerValue.timestamp,
    });

    await _database.child('userChats/$receiverId/$chatRoomId').update({
      'lastMessage': encryptedText,
      'updatedAt': ServerValue.timestamp,
    });
  }

  String _readableText(dynamic value) {
    if (value is! String) {
      return '';
    }
    return _messageEncryptionService.decryptText(value);
  }
}

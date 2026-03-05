import 'package:equatable/equatable.dart';

class ChatPreview extends Equatable {
  const ChatPreview({
    required this.chatId,
    required this.otherUserId,
    this.lastMessage = '',
    this.updatedAt = 0,
  });

  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final int updatedAt;

  factory ChatPreview.fromMap(String chatId, Map<dynamic, dynamic> map) {
    return ChatPreview(
      chatId: chatId,
      otherUserId: (map['otherUserId'] ?? '') as String,
      lastMessage: (map['lastMessage'] ?? '') as String,
      updatedAt: (map['updatedAt'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'otherUserId': otherUserId,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [chatId, otherUserId, lastMessage, updatedAt];
}

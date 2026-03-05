import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final int createdAt;

  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: (map['senderId'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt: (map['createdAt'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [id, senderId, text, createdAt];
}

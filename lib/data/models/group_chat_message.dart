import 'package:equatable/equatable.dart';

class GroupChatMessage extends Equatable {
  const GroupChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final int createdAt;

  factory GroupChatMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    return GroupChatMessage(
      id: id,
      senderId: (map['senderId'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt: (map['createdAt'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [id, senderId, text, createdAt];
}

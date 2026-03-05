import 'package:equatable/equatable.dart';

class GroupChatPreview extends Equatable {
  const GroupChatPreview({
    required this.groupId,
    required this.name,
    this.lastMessage = '',
    this.updatedAt = 0,
  });

  final String groupId;
  final String name;
  final String lastMessage;
  final int updatedAt;

  factory GroupChatPreview.fromMap(String groupId, Map<dynamic, dynamic> map) {
    return GroupChatPreview(
      groupId: groupId,
      name: (map['name'] ?? map['groupName'] ?? 'Group') as String,
      lastMessage: (map['lastMessage'] ?? '') as String,
      updatedAt: (map['updatedAt'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [groupId, name, lastMessage, updatedAt];
}

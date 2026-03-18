import 'package:equatable/equatable.dart';

class GroupChatPreview extends Equatable {
  const GroupChatPreview({
    required this.groupId,
    required this.name,
    this.lastMessage = '',
    this.updatedAt = 0,
    this.iconUrl = '',
  });

  final String groupId;
  final String name;
  final String lastMessage;
  final int updatedAt;
  final String iconUrl;

  factory GroupChatPreview.fromMap(String groupId, Map<dynamic, dynamic> map) {
    return GroupChatPreview(
      groupId: groupId,
      name: (map['name'] ?? map['groupName'] ?? 'Group') as String,
      lastMessage: (map['lastMessage'] ?? '') as String,
      updatedAt: (map['updatedAt'] ?? 0) as int,
      iconUrl: (map['iconUrl'] ?? '') as String,
    );
  }

  @override
  List<Object?> get props => [groupId, name, lastMessage, updatedAt, iconUrl];
}

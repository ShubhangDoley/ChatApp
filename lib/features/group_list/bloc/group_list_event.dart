import 'package:equatable/equatable.dart';

import '../../../data/models/group_chat_preview.dart';

abstract class GroupListEvent extends Equatable {
  const GroupListEvent();

  @override
  List<Object?> get props => [];
}

class GroupListStarted extends GroupListEvent {
  const GroupListStarted();
}

class GroupListUpdated extends GroupListEvent {
  const GroupListUpdated(this.groups);

  final List<GroupChatPreview> groups;

  @override
  List<Object?> get props => [groups];
}

class GroupCreateRequested extends GroupListEvent {
  const GroupCreateRequested({
    required this.name,
    required this.memberIds,
  });

  final String name;
  final List<String> memberIds;

  @override
  List<Object?> get props => [name, memberIds];
}

class GroupListErrorReceived extends GroupListEvent {
  const GroupListErrorReceived(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

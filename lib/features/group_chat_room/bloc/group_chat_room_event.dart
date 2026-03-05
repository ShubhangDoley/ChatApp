import 'package:equatable/equatable.dart';

import '../../../data/models/group_chat_message.dart';

abstract class GroupChatRoomEvent extends Equatable {
  const GroupChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class GroupChatRoomStarted extends GroupChatRoomEvent {
  const GroupChatRoomStarted();
}

class GroupChatRoomInputChanged extends GroupChatRoomEvent {
  const GroupChatRoomInputChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class GroupChatRoomSendMessageRequested extends GroupChatRoomEvent {
  const GroupChatRoomSendMessageRequested();
}

class GroupChatRoomMessagesUpdated extends GroupChatRoomEvent {
  const GroupChatRoomMessagesUpdated(this.messages);

  final List<GroupChatMessage> messages;

  @override
  List<Object?> get props => [messages];
}

class GroupChatRoomErrorReceived extends GroupChatRoomEvent {
  const GroupChatRoomErrorReceived(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

import '../../../data/models/chat_message.dart';

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomStarted extends ChatRoomEvent {
  const ChatRoomStarted();
}

class ChatRoomInputChanged extends ChatRoomEvent {
  const ChatRoomInputChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class ChatRoomSendMessageRequested extends ChatRoomEvent {
  const ChatRoomSendMessageRequested();
}

class ChatRoomMessagesUpdated extends ChatRoomEvent {
  const ChatRoomMessagesUpdated(this.messages);

  final List<ChatMessage> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatRoomErrorReceived extends ChatRoomEvent {
  const ChatRoomErrorReceived(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

import '../../../data/models/chat_message.dart';

enum ChatRoomStatus { initial, loading, ready, sending, failure }

class ChatRoomState extends Equatable {
  const ChatRoomState({
    this.status = ChatRoomStatus.initial,
    this.messages = const [],
    this.input = '',
    this.errorMessage,
  });

  final ChatRoomStatus status;
  final List<ChatMessage> messages;
  final String input;
  final String? errorMessage;

  static const _unset = Object();

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    List<ChatMessage>? messages,
    String? input,
    Object? errorMessage = _unset,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      input: input ?? this.input,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, messages, input, errorMessage];
}

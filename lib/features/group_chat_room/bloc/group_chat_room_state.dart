import 'package:equatable/equatable.dart';

import '../../../data/models/group_chat_message.dart';

enum GroupChatRoomStatus { initial, loading, ready, sending, failure }

class GroupChatRoomState extends Equatable {
  const GroupChatRoomState({
    this.status = GroupChatRoomStatus.initial,
    this.messages = const [],
    this.input = '',
    this.errorMessage,
  });

  final GroupChatRoomStatus status;
  final List<GroupChatMessage> messages;
  final String input;
  final String? errorMessage;

  static const _unset = Object();

  GroupChatRoomState copyWith({
    GroupChatRoomStatus? status,
    List<GroupChatMessage>? messages,
    String? input,
    Object? errorMessage = _unset,
  }) {
    return GroupChatRoomState(
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

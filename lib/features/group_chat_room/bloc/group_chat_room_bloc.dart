import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/group_chat_message.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/group_chat_repository.dart';
import 'group_chat_room_event.dart';
import 'group_chat_room_state.dart';

class GroupChatRoomBloc extends Bloc<GroupChatRoomEvent, GroupChatRoomState> {
  GroupChatRoomBloc({
    required AuthRepository authRepository,
    required GroupChatRepository groupChatRepository,
    required this.groupId,
  }) : _authRepository = authRepository,
       _groupChatRepository = groupChatRepository,
       super(const GroupChatRoomState()) {
    on<GroupChatRoomStarted>(_onStarted);
    on<GroupChatRoomInputChanged>(_onInputChanged);
    on<GroupChatRoomSendMessageRequested>(_onSendMessageRequested);
    on<GroupChatRoomMessagesUpdated>(_onMessagesUpdated);
    on<GroupChatRoomErrorReceived>(_onErrorReceived);
  }

  final AuthRepository _authRepository;
  final GroupChatRepository _groupChatRepository;
  final String groupId;

  StreamSubscription<List<GroupChatMessage>>? _messagesSubscription;

  Future<void> _onStarted(
    GroupChatRoomStarted event,
    Emitter<GroupChatRoomState> emit,
  ) async {
    emit(state.copyWith(status: GroupChatRoomStatus.loading, errorMessage: null));
    final currentUserId = _authRepository.currentUser?.uid;
    if (currentUserId == null) {
      emit(
        state.copyWith(
          status: GroupChatRoomStatus.failure,
          errorMessage: 'User not logged in.',
        ),
      );
      return;
    }

    try {
      await _messagesSubscription?.cancel();
      _messagesSubscription = _groupChatRepository.watchMessages(groupId).listen(
        (messages) {
          add(GroupChatRoomMessagesUpdated(messages));
        },
        onError: (error) {
          add(GroupChatRoomErrorReceived(error.toString()));
        },
      );
      emit(state.copyWith(status: GroupChatRoomStatus.ready));
    } catch (error) {
      emit(
        state.copyWith(
          status: GroupChatRoomStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onInputChanged(
    GroupChatRoomInputChanged event,
    Emitter<GroupChatRoomState> emit,
  ) {
    emit(state.copyWith(input: event.value));
  }

  Future<void> _onSendMessageRequested(
    GroupChatRoomSendMessageRequested event,
    Emitter<GroupChatRoomState> emit,
  ) async {
    final currentUserId = _authRepository.currentUser?.uid;
    final text = state.input.trim();
    if (currentUserId == null || text.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: GroupChatRoomStatus.sending,
        input: '',
        errorMessage: null,
      ),
    );
    try {
      await _groupChatRepository.sendMessage(
        groupId: groupId,
        senderId: currentUserId,
        text: text,
      );
      emit(state.copyWith(status: GroupChatRoomStatus.ready));
    } catch (error) {
      emit(
        state.copyWith(
          status: GroupChatRoomStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onMessagesUpdated(
    GroupChatRoomMessagesUpdated event,
    Emitter<GroupChatRoomState> emit,
  ) {
    emit(
      state.copyWith(
        status: GroupChatRoomStatus.ready,
        messages: event.messages,
        errorMessage: null,
      ),
    );
  }

  void _onErrorReceived(
    GroupChatRoomErrorReceived event,
    Emitter<GroupChatRoomState> emit,
  ) {
    emit(
      state.copyWith(
        status: GroupChatRoomStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}

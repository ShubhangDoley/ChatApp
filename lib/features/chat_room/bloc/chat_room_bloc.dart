import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  ChatRoomBloc({
    required AuthRepository authRepository,
    required ChatRepository chatRepository,
    required this.chatRoomId,
    required this.targetUser,
  }) : _authRepository = authRepository,
       _chatRepository = chatRepository,
       super(const ChatRoomState()) {
    on<ChatRoomStarted>(_onStarted);
    on<ChatRoomInputChanged>(_onInputChanged);
    on<ChatRoomSendMessageRequested>(_onSendMessageRequested);
    on<ChatRoomMessagesUpdated>(_onMessagesUpdated);
    on<ChatRoomErrorReceived>(_onErrorReceived);
  }

  final AuthRepository _authRepository;
  final ChatRepository _chatRepository;
  final String chatRoomId;
  final AppUser targetUser;

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  Future<void> _onStarted(ChatRoomStarted event, Emitter<ChatRoomState> emit) async {
    emit(state.copyWith(status: ChatRoomStatus.loading, errorMessage: null));
    final currentUserId = _authRepository.currentUser?.uid;
    if (currentUserId == null) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          errorMessage: 'User not logged in.',
        ),
      );
      return;
    }

    try {
      await _chatRepository.ensureChatRoom(
        chatRoomId: chatRoomId,
        currentUserId: currentUserId,
        otherUserId: targetUser.uid,
      );

      await _messagesSubscription?.cancel();
      _messagesSubscription = _chatRepository.watchMessages(chatRoomId).listen(
        (messages) {
          add(ChatRoomMessagesUpdated(messages));
        },
        onError: (error) {
          add(ChatRoomErrorReceived(error.toString()));
        },
      );

      emit(state.copyWith(status: ChatRoomStatus.ready));
    } catch (error) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onInputChanged(ChatRoomInputChanged event, Emitter<ChatRoomState> emit) {
    emit(state.copyWith(input: event.value));
  }

  Future<void> _onSendMessageRequested(
    ChatRoomSendMessageRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final currentUserId = _authRepository.currentUser?.uid;
    final text = state.input.trim();
    if (currentUserId == null || text.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: ChatRoomStatus.sending,
        input: '',
        errorMessage: null,
      ),
    );
    try {
      await _chatRepository.sendMessage(
        chatRoomId: chatRoomId,
        senderId: currentUserId,
        receiverId: targetUser.uid,
        text: text,
      );
      emit(state.copyWith(status: ChatRoomStatus.ready));
    } catch (error) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onMessagesUpdated(ChatRoomMessagesUpdated event, Emitter<ChatRoomState> emit) {
    emit(
      state.copyWith(
        status: ChatRoomStatus.ready,
        messages: event.messages,
        errorMessage: null,
      ),
    );
  }

  void _onErrorReceived(ChatRoomErrorReceived event, Emitter<ChatRoomState> emit) {
    emit(state.copyWith(status: ChatRoomStatus.failure, errorMessage: event.message));
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/chat_preview.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../models/home_chat_item.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required AuthRepository authRepository,
    required ChatRepository chatRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _chatRepository = chatRepository,
       _userRepository = userRepository,
       super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeChatsUpdated>(_onChatsUpdated);
    on<HomeProfileImageUploadRequested>(_onProfileImageUploadRequested);
    on<HomeErrorReceived>(_onErrorReceived);
  }

  final AuthRepository _authRepository;
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;
  StreamSubscription<List<ChatPreview>>? _chatSubscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));

    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'User not logged in.',
        ),
      );
      return;
    }

    AppUser? user = await _userRepository.fetchUserById(firebaseUser.uid);
    if (user == null) {
      final email = firebaseUser.email ?? '';
      await _userRepository.createUserProfile(
        uid: firebaseUser.uid,
        email: email,
        name: email.isEmpty ? 'User' : email.split('@').first,
      );
      user = await _userRepository.fetchUserById(firebaseUser.uid);
    }

    emit(state.copyWith(status: HomeStatus.loaded, currentUser: user, chats: const []));

    await _chatSubscription?.cancel();
    _chatSubscription = _chatRepository.watchUserChats(firebaseUser.uid).listen(
      (chats) {
        add(HomeChatsUpdated(chats));
      },
      onError: (error) {
        add(HomeErrorReceived(error.toString()));
      },
    );
  }

  Future<void> _onChatsUpdated(
    HomeChatsUpdated event,
    Emitter<HomeState> emit,
  ) async {
    final items = <HomeChatItem>[];
    for (final chat in event.chats) {
      final user = await _userRepository.fetchUserById(chat.otherUserId);
      if (user != null) {
        items.add(HomeChatItem(chatPreview: chat, otherUser: user));
      }
    }

    emit(state.copyWith(status: HomeStatus.loaded, chats: items, errorMessage: null));
  }

  Future<void> _onProfileImageUploadRequested(
    HomeProfileImageUploadRequested event,
    Emitter<HomeState> emit,
  ) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: event.source,
      imageQuality: 70,
    );
    if (picked == null) {
      return;
    }

    emit(state.copyWith(isUploadingProfile: true, errorMessage: null));
    try {
      final url = await _userRepository.uploadProfilePhoto(
        uid: currentUser.uid,
        imageFile: File(picked.path),
      );
      emit(
        state.copyWith(
          isUploadingProfile: false,
          currentUser: currentUser.copyWith(photoUrl: url),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isUploadingProfile: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onErrorReceived(HomeErrorReceived event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: HomeStatus.failure, errorMessage: event.message));
  }

  @override
  Future<void> close() async {
    await _chatSubscription?.cancel();
    return super.close();
  }
}

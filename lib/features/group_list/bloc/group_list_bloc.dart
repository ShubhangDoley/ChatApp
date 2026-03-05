import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/group_chat_preview.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/group_chat_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'group_list_event.dart';
import 'group_list_state.dart';

class GroupListBloc extends Bloc<GroupListEvent, GroupListState> {
  GroupListBloc({
    required AuthRepository authRepository,
    required GroupChatRepository groupChatRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _groupChatRepository = groupChatRepository,
       _userRepository = userRepository,
       super(const GroupListState()) {
    on<GroupListStarted>(_onStarted);
    on<GroupListUpdated>(_onGroupsUpdated);
    on<GroupCreateRequested>(_onCreateRequested);
    on<GroupListErrorReceived>(_onErrorReceived);
  }

  final AuthRepository _authRepository;
  final GroupChatRepository _groupChatRepository;
  final UserRepository _userRepository;

  StreamSubscription<List<GroupChatPreview>>? _groupsSubscription;

  Future<void> _onStarted(
    GroupListStarted event,
    Emitter<GroupListState> emit,
  ) async {
    emit(state.copyWith(status: GroupListStatus.loading, errorMessage: null));
    final currentUserId = _authRepository.currentUser?.uid;
    if (currentUserId == null) {
      emit(
        state.copyWith(
          status: GroupListStatus.failure,
          errorMessage: 'User not logged in.',
        ),
      );
      return;
    }

    try {
      final users = await _userRepository.fetchAllUsers(excludeUid: currentUserId);
      emit(
        state.copyWith(
          status: GroupListStatus.loaded,
          availableUsers: users,
          errorMessage: null,
        ),
      );

      await _groupsSubscription?.cancel();
      _groupsSubscription = _groupChatRepository.watchUserGroups(currentUserId).listen(
        (groups) {
          add(GroupListUpdated(groups));
        },
        onError: (error) {
          add(GroupListErrorReceived(error.toString()));
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GroupListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onGroupsUpdated(GroupListUpdated event, Emitter<GroupListState> emit) {
    emit(
      state.copyWith(
        status: GroupListStatus.loaded,
        groups: event.groups,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onCreateRequested(
    GroupCreateRequested event,
    Emitter<GroupListState> emit,
  ) async {
    final currentUserId = _authRepository.currentUser?.uid;
    if (currentUserId == null) {
      emit(
        state.copyWith(
          status: GroupListStatus.failure,
          errorMessage: 'User not logged in.',
        ),
      );
      return;
    }

    final name = event.name.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          status: GroupListStatus.failure,
          errorMessage: 'Group name is required.',
        ),
      );
      return;
    }

    if (event.memberIds.isEmpty) {
      emit(
        state.copyWith(
          status: GroupListStatus.failure,
          errorMessage: 'Select at least one member.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: GroupListStatus.creating, errorMessage: null));
    try {
      await _groupChatRepository.createGroup(
        creatorId: currentUserId,
        name: name,
        memberIds: event.memberIds,
      );
      emit(state.copyWith(status: GroupListStatus.loaded));
    } catch (error) {
      emit(
        state.copyWith(
          status: GroupListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onErrorReceived(
    GroupListErrorReceived event,
    Emitter<GroupListState> emit,
  ) {
    emit(
      state.copyWith(
        status: GroupListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _groupsSubscription?.cancel();
    return super.close();
  }
}

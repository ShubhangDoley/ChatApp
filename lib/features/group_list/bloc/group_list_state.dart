import 'package:equatable/equatable.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/group_chat_preview.dart';

enum GroupListStatus { initial, loading, loaded, creating, failure }

class GroupListState extends Equatable {
  const GroupListState({
    this.status = GroupListStatus.initial,
    this.groups = const [],
    this.availableUsers = const [],
    this.errorMessage,
  });

  final GroupListStatus status;
  final List<GroupChatPreview> groups;
  final List<AppUser> availableUsers;
  final String? errorMessage;

  static const _unset = Object();

  GroupListState copyWith({
    GroupListStatus? status,
    List<GroupChatPreview>? groups,
    List<AppUser>? availableUsers,
    Object? errorMessage = _unset,
  }) {
    return GroupListState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      availableUsers: availableUsers ?? this.availableUsers,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, groups, availableUsers, errorMessage];
}

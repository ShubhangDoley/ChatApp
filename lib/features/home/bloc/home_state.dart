import 'package:equatable/equatable.dart';

import '../../../data/models/app_user.dart';
import '../models/home_chat_item.dart';

enum HomeStatus { initial, loading, loaded, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.currentUser,
    this.chats = const [],
    this.isUploadingProfile = false,
    this.errorMessage,
  });

  final HomeStatus status;
  final AppUser? currentUser;
  final List<HomeChatItem> chats;
  final bool isUploadingProfile;
  final String? errorMessage;

  static const _unset = Object();

  HomeState copyWith({
    HomeStatus? status,
    Object? currentUser = _unset,
    List<HomeChatItem>? chats,
    bool? isUploadingProfile,
    Object? errorMessage = _unset,
  }) {
    return HomeState(
      status: status ?? this.status,
      currentUser: currentUser == _unset ? this.currentUser : currentUser as AppUser?,
      chats: chats ?? this.chats,
      isUploadingProfile: isUploadingProfile ?? this.isUploadingProfile,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentUser,
    chats,
    isUploadingProfile,
    errorMessage,
  ];
}

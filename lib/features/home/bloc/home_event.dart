import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/chat_preview.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class HomeChatsUpdated extends HomeEvent {
  const HomeChatsUpdated(this.chats);

  final List<ChatPreview> chats;

  @override
  List<Object?> get props => [chats];
}

class HomeProfileImageUploadRequested extends HomeEvent {
  const HomeProfileImageUploadRequested(this.source);

  final ImageSource source;

  @override
  List<Object?> get props => [source];
}

class HomeErrorReceived extends HomeEvent {
  const HomeErrorReceived(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

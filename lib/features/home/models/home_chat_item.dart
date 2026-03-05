import 'package:equatable/equatable.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/chat_preview.dart';

class HomeChatItem extends Equatable {
  const HomeChatItem({required this.chatPreview, required this.otherUser});

  final ChatPreview chatPreview;
  final AppUser otherUser;

  @override
  List<Object?> get props => [chatPreview, otherUser];
}

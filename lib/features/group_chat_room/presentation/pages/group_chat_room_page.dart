import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/group_chat_repository.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/group_chat_room_bloc.dart';
import '../../bloc/group_chat_room_event.dart';
import '../../bloc/group_chat_room_state.dart';

class GroupChatRoomPage extends StatelessWidget {
  const GroupChatRoomPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupChatRoomBloc>(
      create: (context) => GroupChatRoomBloc(
        authRepository: context.read<AuthRepository>(),
        groupChatRepository: context.read<GroupChatRepository>(),
        groupId: groupId,
      )..add(const GroupChatRoomStarted()),
      child: _GroupChatRoomView(groupName: groupName),
    );
  }
}

class _GroupChatRoomView extends StatefulWidget {
  const _GroupChatRoomView({required this.groupName});

  final String groupName;

  @override
  State<_GroupChatRoomView> createState() => _GroupChatRoomViewState();
}

class _GroupChatRoomViewState extends State<_GroupChatRoomView> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthRepository>().currentUser?.uid;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.sessionStatus != current.sessionStatus,
      listener: (context, state) {
        if (state.sessionStatus == AuthSessionStatus.unauthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocConsumer<GroupChatRoomBloc, GroupChatRoomState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.input != current.input,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          if (_messageController.text != state.input) {
            _messageController.value = TextEditingValue(
              text: state.input,
              selection: TextSelection.collapsed(offset: state.input.length),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.bgColor,
                    child: Icon(Icons.group, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.groupName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(child: _messagesList(state, currentUserId)),
                _composer(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _messagesList(GroupChatRoomState state, String? currentUserId) {
    if (state.status == GroupChatRoomStatus.loading && state.messages.isEmpty) {
      return const LoadingView(message: 'Loading group messages...');
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No messages yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[state.messages.length - 1 - index];
        final isMe = message.senderId == currentUserId;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.bubbleSent : AppTheme.bubbleReceived,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _composer(BuildContext context, GroupChatRoomState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: (value) => context
                      .read<GroupChatRoomBloc>()
                      .add(GroupChatRoomInputChanged(value)),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: state.status == GroupChatRoomStatus.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: state.status == GroupChatRoomStatus.sending
                    ? null
                    : () {
                        context.read<GroupChatRoomBloc>().add(
                          const GroupChatRoomSendMessageRequested(),
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

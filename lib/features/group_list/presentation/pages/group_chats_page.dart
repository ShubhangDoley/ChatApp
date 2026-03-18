import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/group_chat_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../group_chat_room/presentation/pages/group_chat_room_page.dart';
import '../../bloc/group_list_bloc.dart';
import '../../bloc/group_list_event.dart';
import '../../bloc/group_list_state.dart';

class GroupChatsPage extends StatelessWidget {
  const GroupChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupListBloc>(
      create: (context) => GroupListBloc(
        authRepository: context.read<AuthRepository>(),
        groupChatRepository: context.read<GroupChatRepository>(),
        userRepository: context.read<UserRepository>(),
      )..add(const GroupListStarted()),
      child: const _GroupChatsView(),
    );
  }
}

class _GroupChatsView extends StatelessWidget {
  const _GroupChatsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupListBloc, GroupListState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: BlocBuilder<GroupListBloc, GroupListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Group Chats'),
              actions: [
                IconButton(
                  onPressed: state.status == GroupListStatus.creating
                      ? null
                      : () => _openCreateGroupDialog(context, state.availableUsers),
                  icon: const Icon(Icons.group_add_outlined),
                ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, GroupListState state) {
    if (state.status == GroupListStatus.initial ||
        state.status == GroupListStatus.loading) {
      return const LoadingView(message: 'Loading groups...');
    }

    if (state.status == GroupListStatus.failure && state.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? 'Failed to load groups.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.read<GroupListBloc>().add(const GroupListStarted()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'No groups yet',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to create your first group',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.groups.length,
      itemBuilder: (context, index) {
        final group = state.groups[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupChatRoomPage(
                  groupId: group.groupId,
                  groupName: group.name,
                  iconUrl: group.iconUrl,
                ),
              ),
            ),
            leading: group.iconUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(group.iconUrl),
                  )
                : const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.bgColor,
                    child: Icon(Icons.group, color: AppTheme.textSecondary),
                  ),
            title: Text(
              group.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              group.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ),
        );
      },
    );
  }

  Future<void> _openCreateGroupDialog(
    BuildContext context,
    List<AppUser> users,
  ) async {
    final result = await showDialog<_CreateGroupPayload>(
      context: context,
      builder: (_) => _CreateGroupDialog(users: users),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<GroupListBloc>().add(
          GroupCreateRequested(
            name: result.name,
            memberIds: result.memberIds,
          ),
        );
  }
}

class _CreateGroupPayload {
  const _CreateGroupPayload({
    required this.name,
    required this.memberIds,
  });

  final String name;
  final List<String> memberIds;
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog({required this.users});

  final List<AppUser> users;

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final maxDialogHeight = availableHeight * 0.6;

    return AlertDialog(
      title: const Text('Create Group'),
      content: SizedBox(
        width: 360,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select members',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: widget.users.isEmpty
                    ? const Center(
                        child: Text(
                          'No users available.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.builder(
                          itemCount: widget.users.length,
                          itemBuilder: (context, index) {
                            final user = widget.users[index];
                            return CheckboxListTile(
                              dense: true,
                              value: _selectedUserIds.contains(user.uid),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedUserIds.add(user.uid);
                                  } else {
                                    _selectedUserIds.remove(user.uid);
                                  }
                                });
                              },
                              title: Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _CreateGroupPayload(
                name: _nameController.text.trim(),
                memberIds: _selectedUserIds.toList(),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

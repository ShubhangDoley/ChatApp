import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../chat_room/presentation/pages/chat_room_page.dart';
import '../../../group_list/presentation/pages/group_chats_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../splash/presentation/pages/auth_gate.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../../models/home_chat_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        authRepository: context.read<AuthRepository>(),
        chatRepository: context.read<ChatRepository>(),
        userRepository: context.read<UserRepository>(),
      )..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.sessionStatus != current.sessionStatus,
          listener: (context, state) {
            if (state.sessionStatus == AuthSessionStatus.unauthenticated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (_) => false,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final user = state.currentUser;
          final userName = user?.name ?? 'Guest';
          final userEmail = user?.email ?? 'Not logged in';

          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(
              title: const Text(
                'DoodleChat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GroupChatsPage()),
                  ),
                  icon: const Icon(Icons.groups_2_outlined, color: AppTheme.textSecondary),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  ),
                  icon: const Icon(Icons.search, color: AppTheme.textSecondary),
                ),
              ],
            ),
            drawer: _buildDrawer(context, state, userName, userEmail),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchPage()),
              ),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
      return const LoadingView(message: 'Loading chats...');
    }
    if (state.status == HomeStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? 'Failed to load chats.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<HomeBloc>().add(const HomeStarted()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'No conversations yet',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Search users to start chatting',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.chats.length,
      itemBuilder: (context, index) => _chatTile(context, state.chats[index]),
    );
  }

  Widget _chatTile(BuildContext context, HomeChatItem item) {
    final user = item.otherUser;
    final chat = item.chatPreview;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatRoomPage(chatRoomId: chat.chatId, targetUser: user),
          ),
        ),
        leading: user.photoUrl.isNotEmpty
            ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(user.photoUrl))
            : const CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.bgColor,
                child: Icon(Icons.person, color: AppTheme.textSecondary),
              ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    HomeState state,
    String userName,
    String userEmail,
  ) {
    final user = state.currentUser;
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            color: AppTheme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showImageSourcePicker(context),
                  child: Stack(
                    children: [
                      if (state.isUploadingProfile)
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else if (user != null && user.photoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: NetworkImage(user.photoUrl),
                        )
                      else
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Home'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              final shouldLogout = await AppDialogs.confirm(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
              );
              if (shouldLogout == true && context.mounted) {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<HomeBloc>().add(
                  const HomeProfileImageUploadRequested(ImageSource.camera),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<HomeBloc>().add(
                  const HomeProfileImageUploadRequested(ImageSource.gallery),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

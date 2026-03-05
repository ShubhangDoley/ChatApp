import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../chat_room/presentation/pages/chat_room_page.dart';
import '../../bloc/search_bloc.dart';
import '../../bloc/search_event.dart';
import '../../bloc/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (context) => SearchBloc(
        authRepository: context.read<AuthRepository>(),
        userRepository: context.read<UserRepository>(),
      ),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchBloc, SearchState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Search Users')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      context.read<SearchBloc>().add(SearchQueryChanged(value)),
                  decoration: InputDecoration(
                    hintText: 'Enter email to search...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              context.read<SearchBloc>().add(const SearchCleared());
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (state.isLoading) {
      return const LoadingView(message: 'Searching...');
    }

    if (state.results.isEmpty) {
      final text = state.query.isEmpty ? 'Find friends by email' : 'No users found';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.query.isEmpty ? Icons.person_search_outlined : Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length,
      itemBuilder: (context, index) => _userTile(context, state.results[index]),
    );
  }

  Widget _userTile(BuildContext context, AppUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          final currentUserId = context.read<AuthRepository>().currentUser?.uid;
          if (currentUserId == null) {
            return;
          }
          final chatId = context.read<ChatRepository>().buildChatRoomId(
            currentUserId,
            user.uid,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(chatRoomId: chatId, targetUser: user),
            ),
          );
        },
        leading: user.photoUrl.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(user.photoUrl))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          user.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(user.email),
        trailing: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/group_chat_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/message_encryption_service.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import '../features/splash/presentation/pages/auth_gate.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    const configuredEncryptionKey = String.fromEnvironment('CHAT_ENCRYPTION_KEY');
    final messageEncryptionService = MessageEncryptionService(
      encryptionKey: configuredEncryptionKey.isEmpty ? null : configuredEncryptionKey,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
        RepositoryProvider<UserRepository>(create: (_) => UserRepository()),
        RepositoryProvider<ChatRepository>(
          create: (_) => ChatRepository(
            messageEncryptionService: messageEncryptionService,
          ),
        ),
        RepositoryProvider<GroupChatRepository>(
          create: (_) => GroupChatRepository(
            messageEncryptionService: messageEncryptionService,
          ),
        ),
      ],
      child: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
          userRepository: context.read<UserRepository>(),
        )..add(const AuthSubscriptionRequested()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DoodleChat',
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

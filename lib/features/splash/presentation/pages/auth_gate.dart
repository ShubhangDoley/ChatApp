import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../../core/widgets/loading_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.sessionStatus) {
          case AuthSessionStatus.authenticated:
            return const HomePage();
          case AuthSessionStatus.unauthenticated:
            return const LoginPage();
          case AuthSessionStatus.unknown:
            return const Scaffold(body: LoadingView(message: 'Loading...'));
        }
      },
    );
  }
}

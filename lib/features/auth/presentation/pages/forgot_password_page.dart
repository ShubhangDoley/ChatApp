import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.requestStatus != current.requestStatus,
      listener: (context, state) async {
        if (state.requestStatus == AuthRequestStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<AuthBloc>().add(const AuthClearTransientStatus());
        }
        if (state.requestStatus == AuthRequestStatus.passwordResetEmailSent &&
            state.message != null) {
          await AppDialogs.showInfo(
            context,
            title: 'Password Reset',
            message: state.message!,
          );
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthClearTransientStatus());
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Forgot Password')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Send Reset Link',
                  isLoading: state.isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthPasswordResetRequested(_emailController.text),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

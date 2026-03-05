import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import 'otp_page.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.requestStatus != current.requestStatus ||
          previous.verificationId != current.verificationId,
      listener: (context, state) {
        if (state.requestStatus == AuthRequestStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<AuthBloc>().add(const AuthClearTransientStatus());
        }
        if (state.requestStatus == AuthRequestStatus.otpCodeSent &&
            state.verificationId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpPage(verificationId: state.verificationId!),
            ),
          );
          context.read<AuthBloc>().add(const AuthClearTransientStatus());
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Phone Login')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTextField(
                  controller: _phoneController,
                  hintText: 'Enter phone with country code',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Send OTP',
                  isLoading: state.isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthPhoneOtpRequested(_phoneController.text),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../splash/presentation/pages/auth_gate.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.verificationId});

  final String verificationId;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.requestStatus != current.requestStatus ||
          previous.sessionStatus != current.sessionStatus,
      listener: (context, state) {
        if (state.requestStatus == AuthRequestStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<AuthBloc>().add(const AuthClearTransientStatus());
        }
        if (state.sessionStatus == AuthSessionStatus.authenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (_) => false,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Verify OTP')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTextField(
                  controller: _otpController,
                  hintText: 'Enter OTP',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Verify OTP',
                  isLoading: state.isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthPhoneOtpVerifyRequested(
                        verificationId: widget.verificationId,
                        smsCode: _otpController.text,
                      ),
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

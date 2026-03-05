import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository, required UserRepository userRepository})
    : _authRepository = authRepository,
      _userRepository = userRepository,
      super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPhoneOtpRequested>(_onPhoneOtpRequested);
    on<AuthPhoneCodeSent>(_onPhoneCodeSent);
    on<AuthPhoneVerificationFailed>(_onPhoneVerificationFailed);
    on<AuthPhoneAutoVerified>(_onPhoneAutoVerified);
    on<AuthPhoneOtpVerifyRequested>(_onPhoneOtpVerifyRequested);
    on<AuthClearTransientStatus>(_onClearTransientStatus);
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  StreamSubscription<dynamic>? _authSubscription;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges().listen((user) {
      add(AuthUserChanged(user));
    });
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.unauthenticated,
          userId: null,
          userEmail: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        sessionStatus: AuthSessionStatus.authenticated,
        userId: user.uid,
        userEmail: user.email,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Please fill all fields.',
        ),
      );
      return;
    }
    if (event.password.trim().length < 6) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Password must be at least 6 characters.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.loading,
        message: null,
      ),
    );
    try {
      await _authRepository.signInWithEmail(
        email: event.email.trim(),
        password: event.password.trim(),
      );
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.success,
          message: 'Welcome back!',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: _authRepository.mapAuthError(error),
        ),
      );
    }
  }

  Future<void> _onSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Please fill all fields.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.loading,
        message: null,
      ),
    );

    try {
      final credential = await _authRepository.signUpWithEmail(
        email: event.email.trim(),
        password: event.password.trim(),
      );
      final email = event.email.trim();
      await _userRepository.createUserProfile(
        uid: credential.user!.uid,
        email: email,
        name: email.split('@').first,
      );
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.success,
          message: 'Account created successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: _authRepository.mapAuthError(error),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.loading,
        message: null,
      ),
    );
    try {
      await _authRepository.signOut();
      emit(state.copyWith(requestStatus: AuthRequestStatus.idle, message: null));
    } catch (error) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: _authRepository.mapAuthError(error),
        ),
      );
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Enter your email to reset password.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.loading,
        message: null,
      ),
    );
    try {
      await _authRepository.sendPasswordResetEmail(event.email.trim());
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.passwordResetEmailSent,
          message: 'Password reset link sent.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: _authRepository.mapAuthError(error),
        ),
      );
    }
  }

  Future<void> _onPhoneOtpRequested(
    AuthPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final phone = event.phoneNumber.trim();
    if (phone.isEmpty) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Please enter your phone number.',
        ),
      );
      return;
    }
    if (!phone.startsWith('+')) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Include country code (e.g. +91).',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.loading,
        message: null,
      ),
    );
    try {
      await _authRepository.requestPhoneOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          add(AuthPhoneCodeSent(verificationId));
        },
        onVerificationFailed: (errorMessage) {
          add(AuthPhoneVerificationFailed(errorMessage));
        },
        onVerificationCompleted: () {
          add(const AuthPhoneAutoVerified());
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: _authRepository.mapAuthError(error),
        ),
      );
    }
  }

  void _onPhoneCodeSent(AuthPhoneCodeSent event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.otpCodeSent,
        verificationId: event.verificationId,
        message: 'OTP sent successfully.',
      ),
    );
  }

  void _onPhoneVerificationFailed(
    AuthPhoneVerificationFailed event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.failure,
        message: event.message,
      ),
    );
  }

  void _onPhoneAutoVerified(AuthPhoneAutoVerified event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.success,
        message: 'Phone number verified.',
      ),
    );
  }

  Future<void> _onPhoneOtpVerifyRequested(
    AuthPhoneOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.smsCode.trim().isEmpty) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: 'Please enter OTP.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.loading,
        message: null,
      ),
    );
    try {
      await _authRepository.verifyPhoneOtp(
        verificationId: event.verificationId,
        smsCode: event.smsCode.trim(),
      );
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.success,
          message: 'Phone login successful.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          requestStatus: AuthRequestStatus.failure,
          message: _authRepository.mapAuthError(error),
        ),
      );
    }
  }

  void _onClearTransientStatus(
    AuthClearTransientStatus event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        requestStatus: AuthRequestStatus.idle,
        message: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}

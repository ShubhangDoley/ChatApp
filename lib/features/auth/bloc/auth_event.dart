import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final User? user;

  @override
  List<Object?> get props => [user?.uid];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  const AuthSignupRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthPhoneOtpRequested extends AuthEvent {
  const AuthPhoneOtpRequested(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthPhoneOtpVerifyRequested extends AuthEvent {
  const AuthPhoneOtpVerifyRequested({
    required this.verificationId,
    required this.smsCode,
  });

  final String verificationId;
  final String smsCode;

  @override
  List<Object?> get props => [verificationId, smsCode];
}

class AuthPhoneCodeSent extends AuthEvent {
  const AuthPhoneCodeSent(this.verificationId);

  final String verificationId;

  @override
  List<Object?> get props => [verificationId];
}

class AuthPhoneVerificationFailed extends AuthEvent {
  const AuthPhoneVerificationFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthPhoneAutoVerified extends AuthEvent {
  const AuthPhoneAutoVerified();
}

class AuthClearTransientStatus extends AuthEvent {
  const AuthClearTransientStatus();
}

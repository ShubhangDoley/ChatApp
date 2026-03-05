import 'package:equatable/equatable.dart';

enum AuthSessionStatus { unknown, authenticated, unauthenticated }

enum AuthRequestStatus {
  idle,
  loading,
  success,
  failure,
  otpCodeSent,
  passwordResetEmailSent,
}

class AuthState extends Equatable {
  const AuthState({
    this.sessionStatus = AuthSessionStatus.unknown,
    this.requestStatus = AuthRequestStatus.idle,
    this.userId,
    this.userEmail,
    this.verificationId,
    this.message,
  });

  final AuthSessionStatus sessionStatus;
  final AuthRequestStatus requestStatus;
  final String? userId;
  final String? userEmail;
  final String? verificationId;
  final String? message;

  bool get isLoading => requestStatus == AuthRequestStatus.loading;

  static const _unset = Object();

  AuthState copyWith({
    AuthSessionStatus? sessionStatus,
    AuthRequestStatus? requestStatus,
    Object? userId = _unset,
    Object? userEmail = _unset,
    Object? verificationId = _unset,
    Object? message = _unset,
  }) {
    return AuthState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      requestStatus: requestStatus ?? this.requestStatus,
      userId: userId == _unset ? this.userId : userId as String?,
      userEmail: userEmail == _unset ? this.userEmail : userEmail as String?,
      verificationId: verificationId == _unset
          ? this.verificationId
          : verificationId as String?,
      message: message == _unset ? this.message : message as String?,
    );
  }

  @override
  List<Object?> get props => [
    sessionStatus,
    requestStatus,
    userId,
    userEmail,
    verificationId,
    message,
  ];
}

import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl = '',
  });

  final String uid;
  final String email;
  final String name;
  final String photoUrl;

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      uid: (map['uid'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      photoUrl: (map['photoUrl'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  AppUser copyWith({String? uid, String? email, String? name, String? photoUrl}) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [uid, email, name, photoUrl];
}

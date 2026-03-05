import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository({
    FirebaseDatabase? firebaseDatabase,
    FirebaseStorage? firebaseStorage,
  }) : _database = (firebaseDatabase ?? FirebaseDatabase.instance).ref(),
       _storage = firebaseStorage ?? FirebaseStorage.instance;

  final DatabaseReference _database;
  final FirebaseStorage _storage;

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
  }) {
    return _database.child('users/$uid').set({
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': '',
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<AppUser?> fetchUserById(String uid) async {
    final snapshot = await _database.child('users/$uid').get();
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }
    return AppUser.fromMap(snapshot.value as Map<dynamic, dynamic>);
  }

  Future<String?> fetchProfilePhotoUrl(String uid) async {
    final snapshot = await _database.child('users/$uid/photoUrl').get();
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }
    final value = snapshot.value.toString();
    return value.isEmpty ? null : value;
  }

  Future<List<AppUser>> searchUsersByEmail({
    required String email,
    String? excludeUid,
  }) async {
    final snapshot = await _database
        .child('users')
        .orderByChild('email')
        .equalTo(email.trim())
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    final users = <AppUser>[];
    for (final value in data.values) {
      final user = AppUser.fromMap(value as Map<dynamic, dynamic>);
      if (excludeUid != null && user.uid == excludeUid) {
        continue;
      }
      users.add(user);
    }
    return users;
  }

  Future<List<AppUser>> fetchAllUsers({String? excludeUid}) async {
    final snapshot = await _database.child('users').get();
    if (!snapshot.exists || snapshot.value == null) {
      return const <AppUser>[];
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    final users = <AppUser>[];
    for (final value in data.values) {
      final user = AppUser.fromMap(value as Map<dynamic, dynamic>);
      if (excludeUid != null && user.uid == excludeUid) {
        continue;
      }
      users.add(user);
    }

    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();
    await _database.child('users/$uid/photoUrl').set(downloadUrl);
    return downloadUrl;
  }
}

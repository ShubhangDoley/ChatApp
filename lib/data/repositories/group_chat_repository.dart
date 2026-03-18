import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/group_chat_message.dart';
import '../models/group_chat_preview.dart';
import '../services/message_encryption_service.dart';

class GroupChatRepository {
  GroupChatRepository({
    FirebaseDatabase? firebaseDatabase,
    FirebaseStorage? firebaseStorage,
    MessageEncryptionService? messageEncryptionService,
  }) : _database = (firebaseDatabase ?? FirebaseDatabase.instance).ref(),
       _storage = firebaseStorage ?? FirebaseStorage.instance,
       _messageEncryptionService =
           messageEncryptionService ?? MessageEncryptionService();

  final DatabaseReference _database;
  final FirebaseStorage _storage;
  final MessageEncryptionService _messageEncryptionService;

  Stream<List<GroupChatPreview>> watchUserGroups(String userId) {
    return _database
        .child('userGroups/$userId')
        .orderByChild('updatedAt')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <GroupChatPreview>[];
          }

          final value = event.snapshot.value as Map<dynamic, dynamic>;
          final groups = value.entries
              .map((entry) {
                final group = Map<dynamic, dynamic>.from(
                  entry.value as Map<dynamic, dynamic>,
                );
                group['lastMessage'] = _readableText(group['lastMessage']);
                return GroupChatPreview.fromMap(entry.key.toString(), group);
              })
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return groups;
        });
  }

  Stream<List<GroupChatMessage>> watchMessages(String groupId) {
    return _database
        .child('groupMessages/$groupId')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <GroupChatMessage>[];
          }

          final value = event.snapshot.value as Map<dynamic, dynamic>;
          final messages = value.entries
              .map((entry) {
                final message = Map<dynamic, dynamic>.from(
                  entry.value as Map<dynamic, dynamic>,
                );
                message['text'] = _readableText(message['text']);
                return GroupChatMessage.fromMap(entry.key.toString(), message);
              })
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  Future<String> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Group name is required.');
    }

    final uniqueMemberIds = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    uniqueMemberIds.add(creatorId);

    if (uniqueMemberIds.length < 2) {
      throw ArgumentError('A group must have at least 2 members.');
    }

    final groupRef = _database.child('groups').push();
    final groupId = groupRef.key;
    if (groupId == null) {
      throw StateError('Could not allocate group id.');
    }

    final updates = <String, dynamic>{
      'groups/$groupId/groupId': groupId,
      'groups/$groupId/name': normalizedName,
      'groups/$groupId/createdBy': creatorId,
      'groups/$groupId/updatedAt': ServerValue.timestamp,
      'groups/$groupId/createdAt': ServerValue.timestamp,
      'groups/$groupId/members': {
        for (final memberId in uniqueMemberIds) memberId: true,
      },
    };

    for (final memberId in uniqueMemberIds) {
      updates['userGroups/$memberId/$groupId'] = {
        'groupId': groupId,
        'name': normalizedName,
        'lastMessage': '',
        'updatedAt': ServerValue.timestamp,
      };
    }

    await _database.update(updates);
    return groupId;
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String text,
  }) async {
    final encryptedText = _messageEncryptionService.encryptText(text);
    if (!_messageEncryptionService.isEncryptedPayload(encryptedText)) {
      throw StateError('Group message encryption failed. Plaintext blocked.');
    }
    debugPrint('Encrypted group payload prepared: $encryptedText');

    await _database.child('groupMessages/$groupId').push().set({
      'senderId': senderId,
      'text': encryptedText,
      'isEncrypted': true,
      'createdAt': ServerValue.timestamp,
    });

    final members = await _fetchGroupMembers(groupId);
    final updates = <String, dynamic>{
      'groups/$groupId/lastMessage': encryptedText,
      'groups/$groupId/updatedAt': ServerValue.timestamp,
    };

    for (final memberId in members) {
      updates['userGroups/$memberId/$groupId/lastMessage'] = encryptedText;
      updates['userGroups/$memberId/$groupId/updatedAt'] = ServerValue.timestamp;
    }

    await _database.update(updates);
  }

  Future<List<String>> _fetchGroupMembers(String groupId) async {
    final snapshot = await _database.child('groups/$groupId/members').get();
    if (!snapshot.exists || snapshot.value == null) {
      return const <String>[];
    }

    final rawMembers = snapshot.value as Map<dynamic, dynamic>;
    return rawMembers.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key.toString())
        .toList();
  }

  /// Returns a map of {uid -> displayName} for all members of [groupId].
  Future<Map<String, String>> fetchGroupMembersWithNames(String groupId) async {
    final memberIds = await _fetchGroupMembers(groupId);
    final result = <String, String>{};
    for (final uid in memberIds) {
      final userSnapshot = await _database.child('users/$uid').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        final data = userSnapshot.value as Map<dynamic, dynamic>;
        result[uid] = (data['name'] ?? data['email'] ?? uid).toString();
      } else {
        result[uid] = uid;
      }
    }
    return result;
  }

  /// Adds [newMemberIds] to the group and updates their userGroups entry.
  Future<void> addMembersToGroup({
    required String groupId,
    required List<String> newMemberIds,
  }) async {
    if (newMemberIds.isEmpty) return;

    // Fetch current group info for the userGroups entry.
    final groupSnapshot = await _database.child('groups/$groupId').get();
    if (!groupSnapshot.exists || groupSnapshot.value == null) {
      throw StateError('Group $groupId not found.');
    }
    final groupData = groupSnapshot.value as Map<dynamic, dynamic>;
    final groupName = (groupData['name'] ?? 'Group').toString();

    final updates = <String, dynamic>{};
    for (final uid in newMemberIds) {
      updates['groups/$groupId/members/$uid'] = true;
      updates['userGroups/$uid/$groupId'] = {
        'groupId': groupId,
        'name': groupName,
        'lastMessage': '',
        'updatedAt': ServerValue.timestamp,
      };
    }
    await _database.update(updates);
  }

  /// Deletes the group entirely: messages, group node, and all userGroups entries.
  Future<void> deleteGroup(String groupId) async {
    final memberIds = await _fetchGroupMembers(groupId);

    final updates = <String, dynamic>{
      'groups/$groupId': null,
      'groupMessages/$groupId': null,
    };
    for (final uid in memberIds) {
      updates['userGroups/$uid/$groupId'] = null;
    }
    await _database.update(updates);
  }

  /// Uploads [imageFile] as the group icon, stores the URL in Firebase, and
  /// returns the download URL.
  Future<String> uploadGroupIcon({
    required String groupId,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('group_images').child('$groupId.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    final memberIds = await _fetchGroupMembers(groupId);
    final updates = <String, dynamic>{
      'groups/$groupId/iconUrl': url,
    };
    for (final uid in memberIds) {
      updates['userGroups/$uid/$groupId/iconUrl'] = url;
    }
    await _database.update(updates);
    return url;
  }

  /// Returns the stored icon URL for the group, or null if none is set.
  Future<String?> fetchGroupIconUrl(String groupId) async {
    final snapshot = await _database.child('groups/$groupId/iconUrl').get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final value = snapshot.value.toString();
    return value.isEmpty ? null : value;
  }

  String _readableText(dynamic value) {
    if (value is! String) {
      return '';
    }
    return _messageEncryptionService.decryptText(value);
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/group_chat_message.dart';
import '../models/group_chat_preview.dart';
import '../services/message_encryption_service.dart';

class GroupChatRepository {
  GroupChatRepository({
    FirebaseDatabase? firebaseDatabase,
    MessageEncryptionService? messageEncryptionService,
  }) : _database = (firebaseDatabase ?? FirebaseDatabase.instance).ref(),
       _messageEncryptionService =
           messageEncryptionService ?? MessageEncryptionService();

  final DatabaseReference _database;
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

  String _readableText(dynamic value) {
    if (value is! String) {
      return '';
    }
    return _messageEncryptionService.decryptText(value);
  }
}

import 'package:firebase_database/firebase_database.dart';

/// Firebase Realtime Database Helper
///
/// This file shows how to use Firebase Realtime Database
/// instead of Cloud Firestore for real-time chat.
///
/// Key Differences:
/// - Firestore: Uses collections & documents
/// - Realtime DB: Uses JSON tree structure (like a big Map)

class RealtimeDBHelper {
  // Reference to the database
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // ============== MESSAGES ==============

  /// Send a message using Realtime Database
  static Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  }) async {
    // Create a new message reference with auto-generated key
    DatabaseReference newMsgRef = _database
        .child('messages/$chatRoomId')
        .push();

    await newMsgRef.set({
      'senderId': senderId,
      'text': text,
      'createdAt': ServerValue.timestamp, // Server timestamp
    });

    // Update the chat room's last message
    await _database.child('chats/$chatRoomId').update({
      'lastMessage': text,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Listen to messages in real-time
  static Stream<DatabaseEvent> getMessagesStream(String chatRoomId) {
    return _database
        .child('messages/$chatRoomId')
        .orderByChild('createdAt')
        .onValue; // Fires whenever data changes
  }

  // ============== CHATS ==============

  /// Create or update a chat room
  static Future<void> createChatRoom({
    required String chatRoomId,
    required String user1Id,
    required String user2Id,
  }) async {
    await _database.child('chats/$chatRoomId').set({
      'participants': {user1Id: true, user2Id: true},
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Get all chats for a user
  static Stream<DatabaseEvent> getUserChatsStream(String userId) {
    // Note: Realtime DB doesn't have "array-contains" like Firestore
    // We need to structure data differently or use cloud functions
    return _database.child('userChats/$userId').onValue;
  }

  // ============== USERS ==============

  /// Save user data
  static Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    await _database.child('users/$uid').set({
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': '',
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Search user by email
  static Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    final snapshot = await _database
        .child('users')
        .orderByChild('email')
        .equalTo(email)
        .get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      String firstKey = data.keys.first;
      return Map<String, dynamic>.from(data[firstKey]);
    }
    return null;
  }

  /// Get user by ID
  static Future<Map<String, dynamic>?> getUserById(String uid) async {
    final snapshot = await _database.child('users/$uid').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // ============== PRESENCE (Online Status) ==============
  // This is where Realtime DB shines!

  /// Update user online status
  static Future<void> setUserOnline(String uid) async {
    final userStatusRef = _database.child('status/$uid');

    // Set online status
    await userStatusRef.set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });

    // When disconnected, update to offline
    userStatusRef.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Listen to user's online status
  static Stream<DatabaseEvent> getUserStatusStream(String uid) {
    return _database.child('status/$uid').onValue;
  }
}

// ============== USAGE EXAMPLE ==============
/*

// In your chat_room.dart, replace Firestore stream with:

StreamBuilder(
  stream: RealtimeDBHelper.getMessagesStream(widget.chatRoomId),
  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
      Map<dynamic, dynamic> messagesMap = 
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
      
      // Convert to list and sort
      List<MapEntry> messagesList = messagesMap.entries.toList();
      messagesList.sort((a, b) => 
          (b.value['createdAt'] ?? 0).compareTo(a.value['createdAt'] ?? 0));
      
      return ListView.builder(
        reverse: true,
        itemCount: messagesList.length,
        itemBuilder: (context, index) {
          var msg = messagesList[index].value;
          bool isMe = msg['senderId'] == currentUserId;
          // ... build your message bubble
        },
      );
    }
    return Center(child: Text('Start a conversation'));
  },
)

// To send message:
await RealtimeDBHelper.sendMessage(
  chatRoomId: widget.chatRoomId,
  senderId: currentUserId!,
  text: messageController.text,
);

*/

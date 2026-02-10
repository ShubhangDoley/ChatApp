import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoom extends StatefulWidget {
  final String chatRoomId;
  final Map<String, dynamic> targetUserMap;

  const ChatRoom({
    super.key,
    required this.chatRoomId,
    required this.targetUserMap,
  });

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  TextEditingController messageController = TextEditingController();
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color bubbleSent = Color(0xFF5C6BC0);
  static const Color bubbleReceived = Color(0xFFE8EDF2);

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  void _initChatRoom() async {
    // Create/update chat room entry
    await _database.child('chats/${widget.chatRoomId}').update({
      'participants/${currentUserId}': true,
      'participants/${widget.targetUserMap['uid']}': true,
      'updatedAt': ServerValue.timestamp,
    });

    // Add to user's chat list
    await _database.child('userChats/$currentUserId/${widget.chatRoomId}').set({
      'chatId': widget.chatRoomId,
      'otherUserId': widget.targetUserMap['uid'],
      'updatedAt': ServerValue.timestamp,
    });
    await _database
        .child('userChats/${widget.targetUserMap['uid']}/${widget.chatRoomId}')
        .set({
          'chatId': widget.chatRoomId,
          'otherUserId': currentUserId,
          'updatedAt': ServerValue.timestamp,
        });
  }

  void sendMessage() async {
    String msg = messageController.text.trim();
    if (msg.isEmpty) return;

    messageController.clear();

    // Add message to Realtime Database
    await _database.child('messages/${widget.chatRoomId}').push().set({
      'senderId': currentUserId,
      'text': msg,
      'createdAt': ServerValue.timestamp,
    });

    // Update chat room with last message
    await _database.child('chats/${widget.chatRoomId}').update({
      'lastMessage': msg,
      'updatedAt': ServerValue.timestamp,
    });

    // Update in user's chat lists
    await _database
        .child('userChats/$currentUserId/${widget.chatRoomId}')
        .update({'lastMessage': msg, 'updatedAt': ServerValue.timestamp});
    await _database
        .child('userChats/${widget.targetUserMap['uid']}/${widget.chatRoomId}')
        .update({'lastMessage': msg, 'updatedAt': ServerValue.timestamp});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            widget.targetUserMap['photoUrl'] != null &&
                    widget.targetUserMap['photoUrl'] != ''
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      widget.targetUserMap['photoUrl'],
                    ),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: bgColor,
                    child: Icon(Icons.person, size: 20, color: textSecondary),
                  ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUserMap['name'] ?? '',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(color: Colors.green.shade400, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call_outlined, color: textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _database
                  .child('messages/${widget.chatRoomId}')
                  .orderByChild('createdAt')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> messagesMap =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  List<MapEntry> messagesList = messagesMap.entries.toList();
                  messagesList.sort(
                    (a, b) => (b.value['createdAt'] ?? 0).compareTo(
                      a.value['createdAt'] ?? 0,
                    ),
                  );

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: messagesList.length,
                    itemBuilder: (context, index) {
                      var msg = messagesList[index].value;
                      bool isMe = msg['senderId'] == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? bubbleSent : bubbleReceived,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Start a conversation",
                        style: TextStyle(color: textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: textSecondary),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: messageController,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: textSecondary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

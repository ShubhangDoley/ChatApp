import 'package:cloud_firestore/cloud_firestore.dart';
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

  void sendMessage() async {
    String msg = messageController.text.trim();
    if (msg != "") {
      messageController.clear();

      // Message Object
      Map<String, dynamic> messageData = {
        "chatId": widget.chatRoomId,
        "senderId": currentUserId,
        "text": msg,
        "imageUrl": "",
        "createdAt": DateTime.now(),
      };

      // Add to messages collection
      await FirebaseFirestore.instance.collection("messages").add(messageData);

      // Update Chat record for Home screen
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatRoomId)
          .set({
            "chatId": widget.chatRoomId,
            "participants": [currentUserId, widget.targetUserMap["uid"]],
            "lastMessage": msg,
            "updatedAt": DateTime.now(),
          }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            widget.targetUserMap["photoUrl"] != ""
                ? CircleAvatar(
                    radius: 17,
                    backgroundImage: NetworkImage(
                      widget.targetUserMap["photoUrl"],
                    ),
                  )
                : const CircleAvatar(
                    radius: 17,
                    child: Icon(Icons.person, size: 20),
                  ),
            const SizedBox(width: 10),
            Text(widget.targetUserMap["name"]),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .where("chatId", isEqualTo: widget.chatRoomId)
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Error: ${snapshot.error}\n\nNote: If this says 'index required', please click the link in your terminal to create it.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                  if (dataSnapshot.docs.isEmpty) {
                    return const Center(child: Text("Say Hi!"));
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: dataSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> msgMap =
                          dataSnapshot.docs[index].data()
                              as Map<String, dynamic>;

                      bool isMe = msgMap["senderId"] == currentUserId;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                msgMap["text"],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text("Say Hi!"));
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Enter message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

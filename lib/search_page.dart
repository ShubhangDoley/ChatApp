import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_room.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Users")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Enter Email...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: searchController.text.trim().isNotEmpty
                  ? FirebaseFirestore.instance
                        .collection("users")
                        .where("email", isEqualTo: searchController.text.trim())
                        .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.hasData && snapshot.data != null) {
                  QuerySnapshot querySnapshot = snapshot.data as QuerySnapshot;

                  if (querySnapshot.docs.isEmpty) {
                    return const Center(
                      child: Text("No users found with this email"),
                    );
                  }

                  return ListView.builder(
                    itemCount: querySnapshot.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> userMap =
                          querySnapshot.docs[index].data()
                              as Map<String, dynamic>;

                      if (userMap["email"] ==
                          FirebaseAuth.instance.currentUser?.email) {
                        return const SizedBox();
                      }

                      return ListTile(
                        onTap: () async {
                          // Create or find chat room
                          String chatRoomId = getChatRoomId(
                            currentUserId!,
                            userMap["uid"],
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoom(
                                chatRoomId: chatRoomId,
                                targetUserMap: userMap,
                              ),
                            ),
                          );
                        },
                        leading: userMap["photoUrl"] != ""
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  userMap["photoUrl"],
                                ),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(userMap["name"]),
                        subtitle: Text(userMap["email"]),
                        trailing: const Icon(Icons.send),
                      );
                    },
                  );
                }

                return const Center(child: Text("Search for users by email"));
              },
            ),
          ),
        ],
      ),
    );
  }

  String getChatRoomId(String a, String b) {
    if (a.compareTo(b) > 0) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }
}

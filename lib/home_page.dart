import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginpage.dart';
import 'search_page.dart';
import 'chat_room.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? pickedImage;

  pickImage(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) return;
      final tempImage = File(photo.path);
      setState(() {
        pickedImage = tempImage;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  showAlertBox() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick Image from'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
                child: const ListTile(
                  leading: Icon(Icons.camera),
                  title: Text('Camera'),
                ),
              ),
              InkWell(
                onTap: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
                child: const ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('Gallery'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  logout() async {
    bool? shouldLogout = await UiHelper.CustomAlertDialog(
      context,
      "Logout",
      "Are you sure you want to logout?",
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Loginpage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "Not logged in";
    final userName = userEmail != "Not logged in"
        ? userEmail.split('@')[0]
        : "Guest";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      /* Drawer using UiHelper */
      drawer: UiHelper.customDrawer(
        context: context,
        userName: userName,
        userEmail: userEmail,
        pickedImage: pickedImage,
        onProfileTap: () {
          showAlertBox();
        },
        onLogout: () {
          Navigator.pop(context); // Close drawer
          logout(); // Call the logout function
        },
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("chats")
                .where("participants", arrayContains: user!.uid)
                .orderBy("updatedAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                if (dataSnapshot.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No chats yet. Search for users to start talking!",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dataSnapshot.docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> chatMap =
                        dataSnapshot.docs[index].data() as Map<String, dynamic>;

                    // Get other user's UID
                    String otherUserId = chatMap["participants"].firstWhere(
                      (uid) => uid != user.uid,
                    );

                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.hasData) {
                          Map<String, dynamic> targetUserMap =
                              userSnapshot.data!.data() as Map<String, dynamic>;

                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatRoom(
                                    chatRoomId: chatMap["chatId"],
                                    targetUserMap: targetUserMap,
                                  ),
                                ),
                              );
                            },
                            leading: targetUserMap["photoUrl"] != ""
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      targetUserMap["photoUrl"],
                                    ),
                                  )
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(targetUserMap["name"]),
                            subtitle: Text(chatMap["lastMessage"] ?? ""),
                            trailing: const Icon(Icons.keyboard_arrow_right),
                          );
                        }
                        return const SizedBox();
                      },
                    );
                  },
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              return const Center(
                child: Text("Search for users to start chatting!"),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}

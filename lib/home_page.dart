import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String? profileImageUrl;
  bool isUploadingImage = false;

  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Load existing profile image from database
  void _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _database
          .child('users/${user.uid}/photoUrl')
          .get();
      if (snapshot.exists &&
          snapshot.value != null &&
          snapshot.value.toString().isNotEmpty) {
        setState(() => profileImageUrl = snapshot.value.toString());
      }
    }
  }

  // Pick and upload image
  Future<void> pickAndUploadImage(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );
      if (photo == null) return;

      final tempImage = File(photo.path);
      setState(() {
        pickedImage = tempImage;
        isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      // Upload file
      await storageRef.putFile(tempImage);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Save URL to Realtime Database
      await _database.child('users/${user.uid}/photoUrl').set(downloadUrl);

      setState(() {
        profileImageUrl = downloadUrl;
        isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      setState(() => isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  showImagePickerDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Profile Photo',
          style: TextStyle(color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: primaryColor),
              title: Text('Camera', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_outlined, color: primaryColor),
              title: Text('Gallery', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
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
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Loginpage()),
        );
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
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        title: Text(
          "DoodleChat",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(userName, userEmail),
      body: StreamBuilder<DatabaseEvent>(
        stream: _database
            .child('userChats/${user!.uid}')
            .orderByChild('updatedAt')
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

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> chatsMap =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            List<MapEntry> chatsList = chatsMap.entries.toList();
            chatsList.sort(
              (a, b) => (b.value['updatedAt'] ?? 0).compareTo(
                a.value['updatedAt'] ?? 0,
              ),
            );

            if (chatsList.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chatsList.length,
              itemBuilder: (context, index) {
                var chat = chatsList[index].value;
                String otherUserId = chat['otherUserId'];

                return FutureBuilder<DataSnapshot>(
                  future: _database.child('users/$otherUserId').get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData &&
                        userSnapshot.data!.value != null) {
                      Map<String, dynamic> targetUserMap =
                          Map<String, dynamic>.from(
                            userSnapshot.data!.value as Map,
                          );
                      return _buildChatTile(chat, targetUserMap);
                    }
                    return const SizedBox();
                  },
                );
              },
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

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 2,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        ),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer(String userName, String userEmail) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            color: primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: showImagePickerDialog,
                  child: Stack(
                    children: [
                      // Profile Image
                      isUploadingImage
                          ? const CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(profileImageUrl!),
                            )
                          : pickedImage != null
                          ? CircleAvatar(
                              radius: 36,
                              backgroundImage: FileImage(pickedImage!),
                            )
                          : const CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                      // Edit icon
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.home_outlined, color: textSecondary),
                  title: Text('Home', style: TextStyle(color: textPrimary)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.settings_outlined, color: textSecondary),
                  title: Text('Settings', style: TextStyle(color: textPrimary)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 64,
            color: textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "No conversations yet",
            style: TextStyle(color: textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Search for users to start chatting",
            style: TextStyle(
              color: textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    Map<dynamic, dynamic> chat,
    Map<String, dynamic> targetUserMap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoom(
              chatRoomId: chat['chatId'],
              targetUserMap: targetUserMap,
            ),
          ),
        ),
        leading:
            targetUserMap['photoUrl'] != null && targetUserMap['photoUrl'] != ''
            ? CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(targetUserMap['photoUrl']),
              )
            : CircleAvatar(
                radius: 26,
                backgroundColor: bgColor,
                child: Icon(Icons.person, color: textSecondary),
              ),
        title: Text(
          targetUserMap['name'] ?? '',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          chat['lastMessage'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }
}

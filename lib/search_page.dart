import 'package:firebase_database/firebase_database.dart';
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

  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void searchUsers(String email) async {
    if (email.trim().isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      debugPrint('🔍 Searching for: ${email.trim()}');

      final snapshot = await _database
          .child('users')
          .orderByChild('email')
          .equalTo(email.trim())
          .get();

      debugPrint('📦 Snapshot exists: ${snapshot.exists}');
      debugPrint('📦 Snapshot value: ${snapshot.value}');

      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> results = [];

        data.forEach((key, value) {
          debugPrint('👤 Found user: ${value['email']}');
          if (value['email'] != FirebaseAuth.instance.currentUser?.email) {
            results.add(Map<String, dynamic>.from(value));
          }
        });

        setState(() => searchResults = results);
      } else {
        debugPrint('❌ No users found');
        setState(() => searchResults = []);
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
    }

    setState(() => isLoading = false);
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
        title: Text(
          "Search Users",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) => searchUsers(value),
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: "Enter email to search...",
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : searchResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) =>
                        _buildUserTile(searchResults[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          String chatId = getChatRoomId(currentUserId!, user['uid']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoom(chatRoomId: chatId, targetUserMap: user),
            ),
          );
        },
        leading: user['photoUrl'] != ''
            ? CircleAvatar(backgroundImage: NetworkImage(user['photoUrl']))
            : CircleAvatar(
                backgroundColor: bgColor,
                child: Icon(Icons.person, color: textSecondary),
              ),
        title: Text(
          user['name'] ?? '',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user['email'] ?? '',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchController.text.isEmpty
                ? Icons.person_search_outlined
                : Icons.search_off,
            size: 64,
            color: textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            searchController.text.isEmpty
                ? "Find friends by email"
                : "No users found",
            style: TextStyle(color: textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String getChatRoomId(String a, String b) =>
      a.compareTo(b) > 0 ? "${b}_$a" : "${a}_$b";
}

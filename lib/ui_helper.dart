import 'dart:io';
import 'package:flutter/material.dart';

class UiHelper {
  static customTextField(
    TextEditingController controller,
    String text,
    IconData icon,
    bool toHide,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: TextField(
        style: TextStyle(color: Colors.black),
        controller: controller,
        obscureText: toHide,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
          hintText: text,
          suffixIcon: Icon(icon),
        ),
      ),
    );
  }

  static customButton(VoidCallback voidCallback, String text, int w) {
    return SizedBox(
      height: 40,
      width: w.toDouble(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: voidCallback,
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }

  static Future<bool?> CustomAlertDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  /*used for welcome message at the start */
  static Future<void> showAlert(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          alignment: Alignment.bottomCenter,
          backgroundColor: Colors.blue.shade100,
          title: Text(title, style: TextStyle(color: Colors.black)),
          content: Text(message, style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  static Widget customDrawer({
    required BuildContext context,
    required String userName,
    required String userEmail,
    required VoidCallback onLogout,
    File? pickedImage,
    VoidCallback? onProfileTap,
  }) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade400],
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: GestureDetector(
              onTap: onProfileTap,
              child: pickedImage == null
                  ? const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 45, color: Colors.blue),
                    )
                  : CircleAvatar(backgroundImage: FileImage(pickedImage)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  Icons.home_outlined,
                  'Home',
                  () => Navigator.pop(context),
                ),
                // _buildDrawerItem(Icons.person_outline, 'Profile', () {}),
                // _buildDrawerItem(Icons.quiz_outlined, 'My Quizzes', () {}),
                // _buildDrawerItem(
                //   Icons.leaderboard_outlined,
                //   'Leaderboard',
                //   () {},
                // ),
                const Divider(),
                _buildDrawerItem(Icons.settings_outlined, 'Settings', () {}),
                _buildDrawerItem(Icons.info_outline, 'About Us', () {}),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            Icons.logout,
            'Logout',
            onLogout,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}

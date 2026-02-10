import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chatapp/aboutuspage.dart';

class UiHelper {
  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  static customTextField(
    TextEditingController controller,
    String text,
    IconData icon,
    bool toHide,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          obscureText: toHide,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: text,
            hintStyle: TextStyle(color: textSecondary),
            prefixIcon: Icon(icon, color: textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  static customButton(VoidCallback voidCallback, String text, int w) {
    return SizedBox(
      height: 48,
      width: w.toDouble(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: voidCallback,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showAlert(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
                  onTap: onProfileTap,
                  child: pickedImage == null
                      ? const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.white,
                          ),
                        )
                      : CircleAvatar(
                          radius: 32,
                          backgroundImage: FileImage(pickedImage),
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
                ListTile(
                  leading: Icon(Icons.info_outline, color: textSecondary),
                  title: Text('About Us', style: TextStyle(color: textPrimary)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutUsPage()),
                  ),
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
            onTap: onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

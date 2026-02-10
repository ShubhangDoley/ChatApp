import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';
import 'ui_helper.dart';
import 'loginpage.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.CustomAlertDialog(
        context,
        'Error',
        'Please fill all the fields',
      );
    } else {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save to Realtime Database instead of Firestore
        await _database.child('users/${userCredential.user!.uid}').set({
          'uid': userCredential.user!.uid,
          'name': email.split('@')[0],
          'email': email,
          'photoUrl': '',
          'createdAt': ServerValue.timestamp,
        });

        if (mounted)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MyHomePage(title: 'My Home Page'),
            ),
          );
      } on FirebaseAuthException catch (e) {
        if (mounted)
          UiHelper.CustomAlertDialog(context, 'Error', e.code.toString());
      } catch (e) {
        if (mounted) UiHelper.CustomAlertDialog(context, 'Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_rounded, size: 64, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join DoodleChat today',
                  style: TextStyle(color: textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      UiHelper.customTextField(
                        emailController,
                        'Email',
                        Icons.email_outlined,
                        false,
                      ),
                      const SizedBox(height: 4),
                      UiHelper.customTextField(
                        passwordController,
                        'Password',
                        Icons.lock_outline,
                        true,
                      ),
                      const SizedBox(height: 20),
                      UiHelper.customButton(
                        () => signUp(
                          emailController.text,
                          passwordController.text,
                        ),
                        'Sign Up',
                        200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => Loginpage()),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

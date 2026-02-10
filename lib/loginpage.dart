import 'package:flutter/material.dart';
import 'ui_helper.dart';
import 'signuppage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'forgotpassword.dart';
import 'phoneauth.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  static const Color primaryColor = Color(0xFF5C6BC0);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      UiHelper.CustomAlertDialog(
        context,
        'Error',
        'Please fill all the fields',
      );
    } else if (password.length < 6) {
      UiHelper.CustomAlertDialog(
        context,
        'Error',
        'Password must be at least 6 characters',
      );
    } else {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (context.mounted) {
          await UiHelper.showAlert(context, 'Welcome', 'Welcome back!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MyHomePage(title: 'My Home Page'),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        UiHelper.CustomAlertDialog(context, 'Error', e.code.toString());
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
                Icon(Icons.chat_bubble_rounded, size: 64, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'DoodleChat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back!',
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
                        () => login(
                          emailController.text,
                          passwordController.text,
                        ),
                        'Login',
                        200,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => Forgotpassword()),
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => Signuppage()),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: textSecondary.withOpacity(0.3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(color: textSecondary)),
                    ),
                    Expanded(
                      child: Divider(color: textSecondary.withOpacity(0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Phoneauth()),
                  ),
                  icon: Icon(Icons.phone_outlined, color: textSecondary),
                  label: Text(
                    'Login with OTP',
                    style: TextStyle(color: textSecondary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: textSecondary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        'Password must be at least 6 characters long',
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
              builder: (context) => MyHomePage(title: 'My Home Page'),
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
      appBar: AppBar(title: Text('Login Page'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login Page',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            UiHelper.customTextField(
              emailController,
              'Email',
              Icons.email,
              false,
            ),
            UiHelper.customTextField(
              passwordController,
              'Password',
              Icons.password,
              false,
            ),
            SizedBox(height: 15),
            UiHelper.customButton(
              () {
                login(
                  emailController.text.toString(),
                  passwordController.text.toString(),
                );
              },
              'Login',
              100,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Forgotpassword()),
                );
              },
              child: Text(
                'Forgot Password',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Signuppage()),
                    );
                  },
                  child: Text('Sign Up'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('login with OTP'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Phoneauth()),
                      );
                    },
                    child: Text('here'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

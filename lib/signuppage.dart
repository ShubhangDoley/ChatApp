import 'package:cloud_firestore/cloud_firestore.dart';
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

        // Store user info in Firestore
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
              "uid": userCredential.user!.uid,
              "name": email.split('@')[0],
              "email": email,
              "photoUrl": "",
              "createdAt": DateTime.now(),
            });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'My Home Page'),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          UiHelper.CustomAlertDialog(context, 'Error', e.code.toString());
        }
      } catch (e) {
        if (mounted) {
          UiHelper.CustomAlertDialog(context, 'Error', e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up Page'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign Up Page',
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
            SizedBox(height: 30),
            UiHelper.customButton(
              () {
                signUp(
                  emailController.text.toString(),
                  passwordController.text.toString(),
                );
              },
              'Sign Up',
              150,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Loginpage()),
                    );
                  },
                  child: Text("Login"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

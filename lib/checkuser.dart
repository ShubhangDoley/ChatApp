import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'loginpage.dart';

class Checkuser extends StatefulWidget {
  const Checkuser({super.key});

  @override
  State<Checkuser> createState() => _CheckuserState();
}

class _CheckuserState extends State<Checkuser> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the stream is still waiting, check the current user synchronously
        if (snapshot.connectionState == ConnectionState.waiting) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return const MyHomePage(title: "My Home Page");
          } else {
            return const Loginpage();
          }
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MyHomePage(title: "My Home Page");
        } else {
          return const Loginpage();
        }
      },
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ui_helper.dart';
// import 'checkuser.dart';
import 'otpscreen.dart';
import 'home_page.dart';

class Phoneauth extends StatefulWidget {
  const Phoneauth({super.key});

  @override
  State<Phoneauth> createState() => _PhoneauthState();
}

class _PhoneauthState extends State<Phoneauth> {
  TextEditingController phoneController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Auth'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          UiHelper.customButton(
            () async {
              String phone = phoneController.text.trim();
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please enter a phone number")),
                );
                return;
              }
              if (!phone.startsWith("+")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Include country code (e.g. +91)")),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    Center(child: CircularProgressIndicator()),
              );

              try {
                await FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: phone,
                  verificationCompleted:
                      (PhoneAuthCredential credential) async {
                        try {
                          await FirebaseAuth.instance.signInWithCredential(
                            credential,
                          );
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyHomePage(
                                  title: 'Home Page',
                                ), // Assuming MyHomePage is defined or imported
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                          print("Auto Sign-in Error: $e");
                        }
                      },
                  verificationFailed: (FirebaseAuthException e) {
                    Navigator.pop(context); // Close loading
                    print("Verification Failed: ${e.message}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.message}")),
                    );
                  },
                  codeSent: (String verificationId, int? resendToken) {
                    Navigator.pop(context); // Close loading
                    print("Code Sent to: $phone");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Otpscreen(verificationId: verificationId),
                      ),
                    );
                  },
                  codeAutoRetrievalTimeout: (String verificationId) {
                    // Not closing loading here as it usually happens after some time
                  },
                );
              } catch (e) {
                Navigator.pop(context); // Close loading
                print("Unexpected Error: $e");
              }
            },
            'Send OTP',
            250,
          ),
        ],
      ),
    );
  }
}

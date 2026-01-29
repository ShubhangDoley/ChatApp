import 'package:flutter/material.dart';
import 'ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'checkuser.dart';
import 'home_page.dart';

class Otpscreen extends StatefulWidget {
  final String verificationId;
  const Otpscreen({super.key, required this.verificationId});

  @override
  State<Otpscreen> createState() => _OtpscreenState();
}

class _OtpscreenState extends State<Otpscreen> {
  TextEditingController otpController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Screen'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: TextField(
              controller: otpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter your OTP',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          UiHelper.customButton(
            () async {
              String otp = otpController.text.trim();
              if (otp.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Please enter OTP")));
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    Center(child: CircularProgressIndicator()),
              );

              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: widget.verificationId,
                  smsCode: otp,
                );
                await FirebaseAuth.instance
                    .signInWithCredential(credential)
                    .then((value) {
                      Navigator.pop(context); // Close loading
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(title: 'Home Page'),
                        ),
                      );
                    });
              } catch (e) {
                Navigator.pop(context); // Close loading
                print("OTP Verification Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Invalid OTP or error: ${e.toString()}"),
                  ),
                );
              }
            },
            'Verify OTP',
            250,
          ),
        ],
      ),
    );
  }
}

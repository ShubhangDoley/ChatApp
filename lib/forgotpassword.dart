import 'package:flutter/material.dart';
import 'ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'loginpage.dart';
class Forgotpassword extends StatefulWidget {
  const Forgotpassword({super.key});

  @override
  State<Forgotpassword> createState() => _ForgotpasswordState();
}

class _ForgotpasswordState extends State<Forgotpassword> {
  TextEditingController emailController = TextEditingController();
  forgotPassword(String email)async{
    if(email.isEmpty){
      UiHelper.CustomAlertDialog(context, 'Error', 'Enter your email to reset password');
    }
    else{
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password'),centerTitle: true,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Forgot Password',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
            SizedBox(height: 30,),
            UiHelper.customTextField(emailController, 'Email', Icons.email, false),
            SizedBox(height: 30,),
            UiHelper.customButton(() {
              forgotPassword(emailController.text.toString());
            }, 'Reset Password', 250),
          ],
        ),
      ),
    );
  }
}
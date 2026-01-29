/* we will make user to chose a image from gallery or camera for user pfp and then we will store it in firebase storage and then we will store the url in firebase firestore */

import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  File? pickedImage;

  signup(String email, String password) async {
    if (email == "" && password == "" && pickedImage == null) {
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill all the fields'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password)
            .then((value) {
              uploadData(userCredential!.user!.uid);
            });
      } on FirebaseAuthException catch (e) {
        log(e.code.toString());
      }
    }
  }

  showAlertBox() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick Image from'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
                child: ListTile(
                  leading: Icon(Icons.camera),
                  title: Text('Camera'),
                ),
              ),
              InkWell(
                onTap: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
                child: ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('Gallery'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signup'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              showAlertBox();
            },
            child: pickedImage == null
                ? CircleAvatar(radius: 80, child: Icon(Icons.person, size: 80))
                : CircleAvatar(
                    radius: 80,
                    backgroundImage: FileImage(pickedImage!),
                  ),
          ),
          UiHelper.customTextField(
            emailController,
            'Email',
            Icons.email,
            false,
          ),
          SizedBox(height: 30),
          UiHelper.customTextField(
            passwordController,
            'Password',
            Icons.lock,
            true,
          ),
          SizedBox(height: 30),
          UiHelper.customButton(() {
            signup(emailController.text.toString(), passwordController.text.toString());
          }, 'Signup', 250),
        ],
      ),
    );
  }

  pickImage(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) return;
      final tempImage = File(photo.path);
      setState(() {
        // to show picked image
        pickedImage = tempImage;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void uploadData(String uid) async {
    UploadTask uploadTask = FirebaseStorage.instance
        .ref("profile pics")
        .child(emailController.text.toString())
        .putFile(pickedImage!);
    TaskSnapshot taskSnapshot = await uploadTask;
    String url = await taskSnapshot.ref.getDownloadURL();
    FirebaseFirestore.instance
        .collection("users")
        .doc(emailController.text.toString())
        .set({
          "email": emailController.text.toString(),
          // "password": passwordController.text.toString(),
          "image": url,
        })
        .then((value) {
          log("user uploaded!");
        });
  }
}

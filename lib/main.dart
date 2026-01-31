import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'checkuser.dart';
import 'notificationservices.dart';
// import 'aboutuspage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  await Notificationservices.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home:  Checkuser(),
    );
  }
}

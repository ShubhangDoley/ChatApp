import "dart:developer";

import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';


Future<void> backgroundHandler(RemoteMessage message) async {
  log("${message.notification!.title}");
  print("Background Handler: ${message.notification!.title}");
}

class Notificationservices {
  static Future<void> initialize() async {
    NotificationSettings notificationSettings = await FirebaseMessaging.instance
        .requestPermission();
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      FirebaseMessaging.onBackgroundMessage(backgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("onMessage: ${message.data}");
        log("${message.notification!.title}");
      });
      log("Message Authorised");
    }
  }
}

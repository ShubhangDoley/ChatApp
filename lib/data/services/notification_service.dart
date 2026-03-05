import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> backgroundMessageHandler(RemoteMessage message) async {
  log(message.notification?.title ?? 'Background message');
}

class NotificationService {
  static Future<void> initialize() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log(message.notification?.title ?? 'Foreground message');
    });
  }
}

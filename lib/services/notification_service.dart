
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (permission.authorizationStatus ==
          AuthorizationStatus.denied) {
        debugPrint('Notification permission denied');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No logged-in user; token will not be saved');
        return;
      }

      // Get the device FCM token.
      final token = await _messaging.getToken();

      if (token == null) {
        debugPrint('FCM token not available yet');
        return;
      }

      // Save the token to the logged-in user's document.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token saved for current user');

      // Update Firestore when the token changes.
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('FCM token refreshed and saved');
      });
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }
}

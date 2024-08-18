import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '/services/firebase_service.dart';

class FCMNotificationManager {
  static Future<void> sendNotification({
    required FirebaseService firebaseService,
    required String type,
    required String content,
    String? name,
    String? image,
    String? did,
    String? qid,
  }) async {
    Map<String, String>? credentials = await firebaseService.fetchServerDetails();

    if (credentials == null) {
      print('Server key and apiUrl not available.');
      return;
    }

    String? serverKey = credentials['serverKey'];
    String? apiUrl = credentials['apiUrl'];

    if (serverKey == null || apiUrl == null) {
      print('Server key or apiUrl is missing.');
      return;
    }

    apiUrl = apiUrl.trim();

    if (apiUrl.isEmpty) {
      print('ApiUrl is empty.');
      return;
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    String generateUniqueId() {
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int randomValue = Random().nextInt(999999);
      return '$timestamp-$randomValue';
    }

    // Generate a unique notification ID
    String notificationId = generateUniqueId();

    // Fetch notification settings
    QuerySnapshot notificationSettingsSnapshot = await firebaseService
        .notificationsSettings
        .where('notification_type', isEqualTo: 'daily')
        .limit(1)
        .get();

    if (notificationSettingsSnapshot.size == 0) {
      print('Notification settings document does not exist or no matching notification type.');
      return;
    }

    DocumentSnapshot notificationSettingsDoc = notificationSettingsSnapshot.docs[0];

    Map<String, dynamic> notificationSettingsData = notificationSettingsDoc.data() as Map<String, dynamic>;

   String notificationType = notificationSettingsData['notification_type'];
    String topic = notificationSettingsData['topic'];

    // Fetch user devices with consent to receive notifications
    QuerySnapshot userDevicesSnapshot = await firebaseService
        .userDevices
        .where('notification_subscription', isEqualTo: true)
        .get();

    // Send notifications to the fetched user devices
    for (var doc in userDevicesSnapshot.docs) {
      String fcmToken = doc['fcm_token'];
      String userId = doc['id'];
      print('FCM Token (CMS App): $fcmToken');

      Map<String, dynamic> notificationPayload = {
        "to": fcmToken,
        "priority": "high",
        "notification": {
          "title": topic,
          "body": content,
        },
        "data": {
          "type": type,
          "content": content,
          "name": name,
          "image": image,
          "did": did,
          "qid": qid,
          'notification_type': notificationType,
          "notification_id": notificationId,
        },
      };

      try {
        http.Response response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: json.encode(notificationPayload),
        );

        if (response.statusCode == 200) {
          var responseBody = jsonDecode(response.body);
          print(responseBody);
          if(responseBody['results'] != null && responseBody['results'][0]['error'] == 'NotRegistered') {
            // Device is not registered. Probably the app was uninstalled.
            // Update Firestore here...
            await firebaseService.markDeviceAsUninstalled(userId);
            print("App uninstalled or FCM token is not registered");
          } else {
            print("Notification sent successfully!");
            print("Payload: $notificationPayload");

            // Insert notification details into Firestore
            DocumentReference notificationRef = await firebaseService.addDailyNotification({
              'user_id': userId,
              'content_id': qid,
              'content_source': type,
              'sent_date': DateTime.now().millisecondsSinceEpoch,
              'seen': false,
              'clicked': false,
              'notification_id': notificationId,
            });
          }
        } else {
          print("Failed to send notification: ${response.body}");
        }
      } catch (e) {
        print("Error sending notification: $e");
      }
    }
  }

  static Future<void> sendPromoNotification({
    required FirebaseService firebaseService,
    required String title,
    required String body,
  }) async {
    Map<String, String>? credentials = await firebaseService.fetchServerDetails();

    if (credentials == null) {
      print('Server key and FCM token not available.');
      return;
    }

    String? serverKey = credentials['serverKey'];
    String? apiUrl = credentials['apiUrl'];

    if (serverKey == null || apiUrl == null) {
      print('Server key or API URL is missing.');
      return;
    }

    apiUrl = apiUrl.trim();

    if (apiUrl.isEmpty) {
      print('API URL is empty.');
      return;
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    String generateUniqueId() {
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int randomValue = Random().nextInt(999999);
      return '$timestamp-$randomValue';
    }

    // Generate a unique notification ID
    String notificationId = generateUniqueId();

// Fetch notification settings
    QuerySnapshot notificationSettingsSnapshot = await firebaseService
        .notificationsSettings
        .where('notification_type', isEqualTo: 'promo')
        .limit(1)
        .get();

    if (notificationSettingsSnapshot.size == 0) {
      print('Notification settings document does not exist or no matching notification type.');
      return;
    }

    DocumentSnapshot notificationSettingsDoc = notificationSettingsSnapshot.docs[0];

    Map<String, dynamic> notificationSettingsData = notificationSettingsDoc.data() as Map<String, dynamic>;

    String notificationType = notificationSettingsData['notification_type'];
    String topic = notificationSettingsData['topic'];

    // Fetch user devices with consent to receive notifications
    QuerySnapshot userDevicesSnapshot = await firebaseService
        .userDevices
        .where('notification_subscription', isEqualTo: true)
        .get();

    // Send notifications to the fetched user devices
    for (var doc in userDevicesSnapshot.docs) {
      String fcmToken = doc['fcm_token'];
      String userId = doc['id'];
      print('FCM Token (Promo Notification): $fcmToken');

      String url = apiUrl;
      String notificationBody = body.replaceAll('\n\n', '\n');
      String payload = jsonEncode({
        'to': fcmToken,
        'priority': 'high',
        'notification': {
          'title': title,
          'body': notificationBody,
        },
        'data': {
          'topic': topic,
          'notification_type': notificationType,
          'notification_id': notificationId,
        },
      });

      try {
        http.Response response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: payload,
        );

        if (response.statusCode == 200) {
          var responseBody = jsonDecode(response.body);
          print(responseBody);
          if (responseBody['results'] != null && responseBody['results'][0]['error'] == 'NotRegistered') {
            // Device is not registered. Probably the app was uninstalled.
            // Update Firestore here...
            await firebaseService.markDeviceAsUninstalled(userId);
            print("App uninstalled or FCM token is not registered");
          } else {
            print("Notification sent successfully!");
            print("Payload: $payload");

            // Insert notification details into Firestore
            DocumentReference notificationRef = await firebaseService.addPromoNotification({
              'user_id': userId,
              'notification_id': notificationId,
              'message': notificationBody,
              'seen': false,
              'timestamp': FieldValue.serverTimestamp(),
              'title': title,
              'topic': topic,
            });
          }
        } else {
          print("Failed to send notification: ${response.body}");
        }
      } catch (e) {
        print("Error sending notification: $e");
      }
    }
  }

}

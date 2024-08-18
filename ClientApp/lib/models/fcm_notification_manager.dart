import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/content_carousel.dart';
import '/models/content.dart';
import '/screens/start_screen.dart';
import '/models/background_image_util.dart';
import '/models/device_manager.dart';
import '/models/database_helper.dart';

typedef UpdateBackgroundImageCallback = void Function(String backgroundImageLocalUrl);

Future<void> customBackgroundMessageHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class FCMNotificationManager {
  static Future<void> initializeFCM(BuildContext context, ValueNotifier<ThemeMode> themeNotifier, UpdateBackgroundImageCallback updateBackgroundImageCallback) async {
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    DeviceManager deviceManager = DeviceManager(firestore: FirebaseFirestore.instance);

    Future<String?> getFcmTokenWithRetry({int retries = 3, Duration delay = const Duration(seconds: 3)}) async {
      String? fcmToken;
      while (retries > 0 && fcmToken == null) {
        fcmToken = await messaging.getToken();
      }
      return fcmToken;
    }

    String? fcmToken = await getFcmTokenWithRetry();
    // print('FCM Token (Destination App): $fcmToken');

    if (fcmToken != null) {
      messaging.onTokenRefresh.listen((newToken) {
        // print('FCM Token Refreshed (Destination App): $newToken');
        // Update the Firestore entry with the new token
        deviceManager.updateDeviceToken(fcmToken, newToken);
      });
    } else {
      // print('Failed to get FCM token after retries');
    }

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    bool notificationSubscriptionStatus = settings.authorizationStatus == AuthorizationStatus.authorized;

    if (fcmToken != null) {
      await deviceManager.addDeviceToFirestore(context, fcmToken, notificationSubscriptionStatus);
    } else {
      // If fcmToken is null, pass it to the function anyway, it will handle it.
      await deviceManager.addDeviceToFirestore(context, null, notificationSubscriptionStatus);
      // print("Failed to get FCM token");
    }

    if (!notificationSubscriptionStatus) {
      // print('User declined or has not granted permission for notifications.');
    }

    //Handle message when the app is in the background but opened up by tapping the notification
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        //   print('App was launched from a notification!');
        //   print('Message received: ${message.data}');
        onSelectNotification(context, jsonDecode(jsonEncode(message.data)), themeNotifier, updateBackgroundImageCallback);
      }
    });

    //Handle message when the app is in the background and opened up normally
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('onMessageOpenedApp event was published!');
      //   print('Message received: ${message.data}');
      onSelectNotification(context, message.data, themeNotifier, updateBackgroundImageCallback);
    });

    //Handle message when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //   print('A new onMessage event was published!');
      //   print('Message received: ${message.data}');
      onSelectNotification(context, message.data, themeNotifier, updateBackgroundImageCallback);
    });

    FirebaseMessaging.onBackgroundMessage(customBackgroundMessageHandler);
  }

  static Future<void> onSelectNotification(BuildContext context, Map<String, dynamic> contentData, ValueNotifier<ThemeMode> themeNotifier, UpdateBackgroundImageCallback updateBackgroundImageCallback) async {
    if (contentData.isNotEmpty) {

      String notificationType = contentData['notification_type'] ?? '';
      String notificationId = contentData['notification_id'] ?? '';

      if(notificationType=='promo'){
        // Get a reference to the daily_quote_notifications collection
        CollectionReference promoNotificationsCollection = FirebaseFirestore.instance.collection('promo_notifications');

        // Query the collection to find the document with the matching notification_id
        QuerySnapshot querySnapshot = await promoNotificationsCollection.where('notification_id', isEqualTo: notificationId).get();

        if (querySnapshot.size > 0) {
          // Get the first document in the result (assuming there's only one)
          DocumentSnapshot promoNotificationDocument = querySnapshot.docs[0];

          // Update the clicked and seen fields
          await promoNotificationDocument.reference.update({
            'seen': true,
          });
        }
      } else{
        // Deserialize the payload and get the qid and type
        String qid = contentData['qid'] ?? '';
        String type = contentData['type'] ?? '';

        bool isAuthorContent = type == 'author';
        bool isCategoryContent = type == 'category';
        bool isCultureContent = type == 'culture';

        DatabaseHelper dbHelper = DatabaseHelper.instance;

        // Fetch the content details from SQLite database using the 'qid' field
        Map<String, dynamic>? contentDetails = await dbHelper.getContentById(qid, type);
        String? authorId;
        String? categoryId;
        String? cultureId;

        if (contentDetails == null) {
          // print("Content details not found in SQLite database");
          // Fetch and save the content from Firestore
          //quoteDetails = await dbHelper.fetchAndSaveContent(qid, type == 'author');
          contentDetails = await dbHelper.fetchAndSaveContent(qid, isAuthorContent, isCultureContent, isCategoryContent);

          if (contentDetails == null) {
            // print("Content details not found in Firestore either");
            // Exit from the method since we don't have content details
            return;
          }
        }

        if (isAuthorContent) {
          authorId = contentDetails['author_id'];
        } else if (isCultureContent) {
          cultureId = contentDetails['culture_id'];
        } else {
          categoryId = contentDetails['category_id'];
        }
        String? authorName;
        String? categoryName;
        String? cultureName;
        String? authorImagePath;
        String? cultureImagePath;

        // Fetch author details from SQLite database if available
        if (authorId != null) {
          Map<String, dynamic>? authorDetails = await dbHelper.getAuthorById(authorId);
          if (authorDetails == null) {
            //   print("Author details not found in SQLite database");
            // Fetch and save the author from Firestore
            authorDetails = await dbHelper.fetchAndSaveAuthor(authorId);
            if (authorDetails == null) {
              //  print("Author details not found in Firestore either");
              // Exit from the method since we don't have author details
              return;
            }
          }
          authorName = authorDetails['name'];
          authorImagePath = authorDetails['image_remote'];
          contentDetails = Map<String, dynamic>.from(contentDetails);
          contentDetails['authorName'] = authorName;
        }

        // Fetch category details from SQLite database if available
        if (categoryId != null) {
          Map<String, dynamic>? categoryDetails = await dbHelper.getCategoryById(categoryId);
          if (categoryDetails == null) {
            //  print("Category details not found in SQLite database");
            // Fetch and save the category from Firestore
            categoryDetails = await dbHelper.fetchAndSaveCategory(categoryId);
            if (categoryDetails == null) {
              //  print("Category details not found in Firestore either");
              // Exit from the method since we don't have category details
              return;
            }
          }
          categoryName = categoryDetails['name'];

          contentDetails = Map<String, dynamic>.from(contentDetails);
          contentDetails['name'] = categoryName;
          contentDetails['categoryName'] = categoryName;
        }

        // Fetch culture details from SQLite database if available
        if (cultureId != null) {
          Map<String, dynamic>? cultureDetails = await dbHelper.getCultureById(cultureId);
          if (cultureDetails == null) {
            //   print("Culture details not found in SQLite database");
            // Fetch and save the culture from Firestore
            cultureDetails = await dbHelper.fetchAndSaveCulture(cultureId);
            if (cultureDetails == null) {
              //   print("Culture details not found in Firestore either");
              // Exit from the method since we don't have culture details
              return;
            }
          }

          cultureName = cultureDetails['name'];
          cultureImagePath = cultureDetails['image_remote'];
          contentDetails = Map<String, dynamic>.from(contentDetails);
          contentDetails['name'] = cultureName;
          contentDetails['cultureName'] = cultureName;
        }

        // print('Notification Data');
        // print(authorImagePath);
        //print(authorName);
        // print(categoryName);
        // print(cultureName);

        // Construct the selectedContent object
        Content selectedContent = Content(
          content: contentDetails['content'] ?? '',
          author: authorName ?? '',
          category: categoryName ?? '',
          culture: cultureName ?? '',
          name: (type == 'author' ? authorName : (type == 'culture' ? cultureName : categoryName)) ?? '',
          image: (type == 'author' ? authorImagePath : (type == 'culture' ? cultureImagePath : '')) ?? '',
          id: (type == 'author' ? authorId : (type == 'culture' ? cultureId : categoryId)) ?? '',
          type: type ?? '',
          authorImagePath: authorImagePath ?? '',
          cultureImagePath: cultureImagePath ?? '',
        );

        // Get a reference to the daily_quote_notifications collection
        CollectionReference notificationsCollection = FirebaseFirestore.instance.collection('daily_notifications');

        // Query the collection to find the document with the matching notification_id
        QuerySnapshot querySnapshot = await notificationsCollection.where('notification_id', isEqualTo: notificationId).get();

        if (querySnapshot.size > 0) {
          // Get the first document in the result (assuming there's only one)
          DocumentSnapshot notificationDocument = querySnapshot.docs[0];

          // Update the clicked and seen fields
          await notificationDocument.reference.update({
            'clicked': true,
            'seen': true,
          });
        }

        ThemeData notificationScreenAppBarThemeLight = ThemeData.light().copyWith(
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey.shade200,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'CormorantGaramond',
            ),
          ),
        );

        ThemeData notificationScreenAppBarThemeDark = ThemeData.dark().copyWith(
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[850]!,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'CormorantGaramond',
            ),
          ),
        );

        ThemeData currentTheme = themeNotifier.value == ThemeMode.light
            ? ThemeData.light()
            : ThemeData.dark();

        ThemeData appBarTheme = themeNotifier.value == ThemeMode.light
            ? notificationScreenAppBarThemeLight
            : notificationScreenAppBarThemeDark;

        // Navigate to the ContentCarousel screen with the selected content
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MaterialApp(
              theme: currentTheme,
              home: Theme(
                data: appBarTheme,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(selectedContent.name ?? 'AppName'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  body: ContentCarousel(
                    content: contentDetails != null ? [contentDetails] : [],
                    favoriteContent: const {},
                    selectedContent: selectedContent,
                    fromNotification: true,
                    authorImagePath: selectedContent.authorImagePath,
                    cultureImagePath: selectedContent.cultureImagePath,
                    onBackgroundImageChange: () async {
                      String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                      updateBackgroundImageCallback(newBackgroundImageLocalUrl);
                    },
                    backgroundImageEnabled: ValueNotifier<bool>(true),
                    contentId: qid,
                    isAuthorContent: isAuthorContent,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // If quoteData is null or empty, navigate to the home screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const StartScreen(), // Replace this with your actual home screen widget
        ),
      );
    }
  }
}

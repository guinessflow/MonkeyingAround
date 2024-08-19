import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceManager {
  final FirebaseFirestore firestore;

  DeviceManager({required this.firestore});

  Future<Map<String, String>> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo? androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceName': androidInfo.model ?? 'Unknown',
          'deviceId': androidInfo.id ?? 'Unknown',
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo? iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceName': iosInfo.utsname.machine ?? 'Unknown',
          'deviceId': iosInfo.identifierForVendor ?? 'Unknown',
        };
      }
    } catch (e) {
      // print('Failed to get device info: $e');
    }

    // Default values for unknown platforms or errors
    return {'deviceName': 'Unknown', 'deviceId': 'Unknown'};
  }

  Future<String> getIPAddress() async {
    try {
      http.Response response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['ip'];
      } else {
        throw Exception('Failed to fetch IP address');
      }
    } catch (e) {
      //  print('Failed to get IP address: $e');
      return 'Unknown';
    }
  }

  Future<String?> getUserId() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    } else {
      return null;
    }
  }

  Future<Position> getCurrentLocation() async {
    // Request location permissions
    PermissionStatus permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      try {
        Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return currentPosition;
      } catch (e) {
        // Handle the error as needed
        return Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0, // Provide a default value here as well
          headingAccuracy: 0.0, // Provide a default value here as well
        );
      }
    } else {
      // Handle the case where location permission is not granted
      return Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0, // Provide a default value here as well
        headingAccuracy: 0.0, // Provide a default value here as well
      );
    }
  }

  Future<void> addDeviceToFirestore(BuildContext context, String? fcmToken, bool notificationSubscriptionStatus) async {
    // Gather additional device information
    Map<String, String> deviceInfo = await getDeviceInfo();
    String deviceId = deviceInfo['deviceId']!;
    String deviceName = deviceInfo['deviceName']!;
    String ipAddress = await getIPAddress();
    Position currentPosition = await getCurrentLocation();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    DateTime now = DateTime.now();
    String lastActive = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // Check if the user is signed in
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? userId = currentUser?.uid;

    // Add the device information to Firestore with the device ID as the document ID
    Map<String, dynamic> deviceData = {
      'device_id': deviceId,
      'notification_subscription': notificationSubscriptionStatus,
      'location': GeoPoint(currentPosition.latitude, currentPosition.longitude),
      'ip_address': ipAddress,
      'install_status': 'Installed',
      'device_name': deviceName,
      'app_version': packageInfo.version,
      'last_active': lastActive,
      'timestamp': now, // Add the timestamp field
      'user_agent': 'App (${Platform.operatingSystem})',
    };

    // Set userId and fcmToken fields if available
    if (userId != null) {
      deviceData['user_id'] = userId;
    }

    if (fcmToken != null) {
      deviceData['fcm_token'] = fcmToken;
    }

    // Add the device information to Firestore
    await firestore.collection('user_devices').doc(deviceId).set(deviceData);

    // Device information added to Firestore
  }


  Future<void> updateDeviceToken(String oldToken, String newToken) async {
    // Update the device tokens in both user_devices and customers collections
    WriteBatch batch = firestore.batch();

    // Update the device tokens in the user_devices collection
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await firestore.collection('user_devices').where('fcm_token', isEqualTo: oldToken).get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'fcm_token': newToken});
      }
    }

    // Update the device tokens in the customers collection
    QuerySnapshot<Map<String, dynamic>> customerSnapshot =
    await firestore.collection('customers').where('fcm_token', isEqualTo: oldToken).get();

    if (customerSnapshot.docs.isNotEmpty) {
      for (var doc in customerSnapshot.docs) {
        batch.update(doc.reference, {'fcm_token': newToken});
      }
    }

    // Commit the batch update
    await batch.commit();
  }

}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> getDailyContentSubscription({required String userId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isSubscribed = prefs.getBool('notification_subscription_$userId');

    return isSubscribed ?? false;
  }

  static Future<void> setDailyContentSubscription(
      {required String userId, required bool isEnabled}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_subscription_$userId', isEnabled);

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
        .collection('user_devices')
        .where('id', isEqualTo: userId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot<Map<String, dynamic>> userDeviceSnapshot = querySnapshot.docs.first;
      await userDeviceSnapshot.reference.update({'notification_subscription': isEnabled});
    }
  }
}

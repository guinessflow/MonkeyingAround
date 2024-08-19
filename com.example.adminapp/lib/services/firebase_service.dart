import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {

  static const categoryTable = 'categories';
  static const authorTable = 'authors';
  static const cultureTable = 'cultures';
  static const backgroundimagesTable = 'background_images';
  static const authorContentTable = 'author_content';
  static const categoryContentTable = 'category_content';
  static const cultureContentTable = 'culture_content';
  static const userDevicesTable = 'user_devices';
  static const notificationsTable = 'daily_notifications';
  static const promoNotificationsTable = 'promo_notifications';
  static const notificationSettingsTable = 'notifications_settings';
  static const fcmCredentialsTable = 'fcm_credentials';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Add a method to fetch the server key and apiUrl
  Future<Map<String, String>?> fetchServerDetails() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(fcmCredentialsTable)
          .doc('serverkey')
          .get();

      if (snapshot.exists) {
        // Retrieve the server key and apiUrl values from the document
        String serverKey = snapshot.data()?['key'];
        String apiUrl = snapshot.data()?['apiUrl'];

        return {'serverKey': serverKey, 'apiUrl': apiUrl};
      } else {
        print('Server key document does not exist.');
        return null;
      }
    } catch (e) {
      print('Failed to fetch server key and apiUrl: $e');
      return null;
    }
  }

  // Add the categories getter
  CollectionReference get categories => _firestore.collection(categoryTable);

  // Add the authors getter
  CollectionReference get authors => _firestore.collection(authorTable);

  // Add the cultures getter
  CollectionReference get cultures => _firestore.collection(cultureTable);

  // Add the author_content getter
  CollectionReference get authorContent =>
      _firestore.collection(authorContentTable);

  // Add the category_content getter
  CollectionReference get categoryContent =>
      _firestore.collection(categoryContentTable);

  // Add the cultures_content getter
  CollectionReference get cultureContent =>
      _firestore.collection(cultureContentTable);

  // Your Firebase methods will be implemented here
  Future<void> addCategory(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(categoryTable).add(data);
  }

  Future<void> addAuthor(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(authorTable).add(data);
  }

  Future<void> addCulture(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(cultureTable).add(data);
  }

  Future<void> addBackgroundImg(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(backgroundimagesTable).add(data);
  }

  Future<void> addAuthorContent(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(authorContentTable).add(data);
  }

  Future<void> addCategoryContent(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(categoryContentTable).add(data);
  }

  Future<void> addCultureContent(Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(cultureContentTable).add(data);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return _firestore.collection(categoryTable).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAuthors() {
    return _firestore.collection(authorTable).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCultures() {
    return _firestore.collection(cultureTable).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAuthorContent() {
    return _firestore.collection(authorContentTable).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoryContent() {
    return _firestore.collection(categoryContentTable).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCultureContent() {
    return _firestore.collection(cultureContentTable).snapshots();
  }

  Future<void> editCategory(String categoryId,
      Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(categoryTable).doc(categoryId).update(data);
  }

  Future<void> editAuthor(String authorId, Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(authorTable).doc(authorId).update(data);
  }

  Future<void> editCulture(String cultureId, Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(cultureTable).doc(cultureId).update(data);
  }

  Future<void> editAuthorContent(String contentId,
      Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(authorContentTable).doc(contentId).update(data);
  }

  Future<void> editCategoryContent(String contentId,
      Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(categoryContentTable).doc(contentId).update(data);
  }

  Future<void> editCultureContent(String contentId,
      Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore.collection(cultureContentTable).doc(contentId).update(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection(categoryTable).doc(categoryId).delete();
  }

  Future<void> deleteAuthor(String authorId) async {
    await _firestore.collection(authorTable).doc(authorId).delete();
  }

  Future<void> deleteCulture(String cultureId) async {
    await _firestore.collection(cultureTable).doc(cultureId).delete();
  }

  Future<void> deleteAuthorContent(String contentId) async {
    await _firestore.collection(authorContentTable).doc(contentId).delete();
  }

  Future<void> deleteCategoryContent(String contentId) async {
    await _firestore.collection(categoryContentTable).doc(contentId).delete();
  }

  Future<void> deleteCultureContent(String contentId) async {
    await _firestore.collection(cultureContentTable).doc(contentId).delete();
  }

  Future<void> addContent(Map<String, dynamic> data, bool isAuthorContent, bool isCategoryContent, bool isCultureContent) async {
    data['timestamp'] = FieldValue.serverTimestamp();

    if (isAuthorContent) {
      await _firestore.collection(authorContentTable).add(data);
    } else if (isCategoryContent) {
      await _firestore.collection(categoryContentTable).add(data);
    } else if (isCultureContent) {
      await _firestore.collection(cultureContentTable).add(data);
    }
  }

  Stream<QuerySnapshot> getContent({bool isAuthorContent = true, bool isCultureContent = false}) {

    if (isAuthorContent) {
      return _firestore.collection(authorContentTable).orderBy('timestamp', descending: true).snapshots();
    } else if (isCultureContent) {
      return _firestore.collection(cultureContentTable).orderBy('timestamp', descending: true).snapshots();
    } else {
      return _firestore.collection(categoryContentTable).orderBy('timestamp', descending: true).snapshots();
    }
  }


  List<String> _generateKeywords(String query) {
    List<String> keywords = [];
    String keyword = '';

    for (int i = 0; i < query.length; i++) {
      keyword += query[i].toLowerCase();
      keywords.add(keyword);
    }

    return keywords;
  }

  Stream<QuerySnapshot> searchContent(String query, {bool isAuthorContent = true, bool isCultureContent = false}) {

    List<String> searchKeywords = _generateKeywords(query);

    CollectionReference collection;

    if (isAuthorContent) {
      collection = _firestore.collection(authorContentTable);
    } else if (isCultureContent) {
      collection = _firestore.collection(cultureContentTable);
    } else {
      collection = _firestore.collection(categoryContentTable);
    }

    Query queryRef = collection
        .orderBy('timestamp', descending: true)
        .where('keywords', arrayContainsAny: searchKeywords);

    return queryRef.snapshots();
  }


  Stream<QuerySnapshot> filterContent(String filter, String selectedItem, {bool isAuthorContent = true, bool isCultureContent = false}) {

    CollectionReference collection;

    if (isAuthorContent) {
      collection = _firestore.collection(authorContentTable);
    } else if (isCultureContent) {
      collection = _firestore.collection(cultureContentTable);
    } else {
      collection = _firestore.collection(categoryContentTable);
    }

    Query query = collection
        .orderBy('timestamp', descending: true)
        .where(filter, isEqualTo: selectedItem);

    return query.snapshots();
  }


  Future<void> deleteContent(String id, bool isAuthorContent, bool isCultureContent) {
    if (isAuthorContent) {
      return _firestore.collection(authorContentTable).doc(id).delete();
    } else if (isCultureContent) {
      return _firestore.collection(cultureContentTable).doc(id).delete();
    } else {
      return _firestore.collection(categoryContentTable).doc(id).delete();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCategoryById(String categoryId) async {
    return await _firestore.collection(categoryTable).doc(categoryId).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getAuthorById(String authorId) async {
    return await _firestore.collection(authorTable).doc(authorId).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCultureById(String cultureId) async {
    return await _firestore.collection(cultureTable).doc(cultureId).get();
  }

  // Add the user_devices getter
  CollectionReference get userDevices => _firestore.collection(userDevicesTable);

  // Add the daily_notifications getter
  CollectionReference get dailyNotifications =>
      _firestore.collection(notificationsTable);

  CollectionReference get promoNotifications =>
      _firestore.collection(promoNotificationsTable);

  CollectionReference get notificationsSettings =>
      _firestore.collection(notificationSettingsTable);

  // ... existing methods ...

  Future<QuerySnapshot> getUserDevices() async {
    return await userDevices.get();
  }

  Future<DocumentReference> addDailyNotification(
      Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    return await dailyNotifications.add(data);
  }

  Future<DocumentReference> addPromoNotification(
      Map<String, dynamic> data) async {
    data['timestamp'] = FieldValue.serverTimestamp();
    return await promoNotifications.add(data);
  }

  Future<void> markDeviceAsUninstalled(String userId) async {
    QuerySnapshot userDevicesSnapshot = await _firestore.collection(userDevicesTable)
        .where('user_id', isEqualTo: userId)
        .get();

    for (var doc in userDevicesSnapshot.docs) {
      await doc.reference.update({
        'install_status': 'Uninstalled',
      });
    }
  }
}
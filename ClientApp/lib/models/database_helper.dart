import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'device_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/utils.dart';

class DatabaseHelper {
  Future<void> init() async {
    _database = await _initDatabase();
  }

  static const _databaseName = 'database.db';
  static const _databaseVersion = 2;

  // Add Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static const tableCategories = 'categories';
  static const tableAuthors = 'authors';
  static const tableCategoryContent = 'category_content';
  static const tableAuthorContent = 'author_content';

  static const tableCultures = 'cultures';
  static const tableCultureContent = 'culture_content';

  static const tableBackgroundImages = 'background_images';
  static const tableNotifications = 'daily_notifications';
  static const tableDevices = 'user_devices';
  static const tableDeviceFavoriteContent = 'user_favorites';

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  // Only allow a single open connection to the database.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _onConfigure(Database db) async {

  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'database.db');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate, // Make sure this is a method, not a getter
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

// Define the _onCreate method
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS categories(id TEXT PRIMARY KEY, name TEXT, icon_remote TEXT, icon_local TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS authors(id TEXT PRIMARY KEY, name TEXT, image_remote TEXT, image_local TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS category_content(id TEXT PRIMARY KEY, content TEXT, category_id TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS author_content(id TEXT PRIMARY KEY, content TEXT, author_id TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS cultures(id TEXT PRIMARY KEY, name TEXT, image_remote TEXT, image_local TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS culture_content(id TEXT PRIMARY KEY, content TEXT, culture_id TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS background_images(id TEXT PRIMARY KEY, content_type TEXT, back_img_local_url TEXT, back_img_remote_url TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS daily_notifications(id TEXT PRIMARY KEY, user_id TEXT, content_id TEXT, content_source TEXT, sent_date INTEGER, seen INTEGER, clicked INTEGER, notification_id TEXT, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS user_devices(id TEXT PRIMARY KEY, device_name TEXT, user_agent TEXT, ip_address TEXT, location TEXT, fcm_token TEXT, app_install_date INTEGER, install_status INTEGER, uninstall_date INTEGER, last_active INTEGER, timestamp INTEGER)');
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS user_favorites(id TEXT PRIMARY KEY, user_id TEXT, content_id TEXT, favorite_status INTEGER, last_updated INTEGER, timestamp INTEGER)');
    });
  }


  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      // Drop existing tables
      await txn.execute('DROP TABLE IF EXISTS categories');
      await txn.execute('DROP TABLE IF EXISTS authors');
      await txn.execute('DROP TABLE IF EXISTS user_favorites');
      await txn.execute('DROP TABLE IF EXISTS category_content');
      await txn.execute('DROP TABLE IF EXISTS author_content');
      await txn.execute('DROP TABLE IF EXISTS cultures');
      await txn.execute('DROP TABLE IF EXISTS culture_content');
      await txn.execute('DROP TABLE IF EXISTS background_images');
      await txn.execute('DROP TABLE IF EXISTS user_devices');
      await txn.execute('DROP TABLE IF EXISTS daily_notifications');
      // Recreate tables
      _onCreate(db, newVersion);
    });
  }

  // Add a method to check if the local database is empty
  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    List<Map<String, dynamic>> categoriesCount = await db.rawQuery('SELECT COUNT(*) AS count FROM $tableCategories');
    List<Map<String, dynamic>> authorsCount = await db.rawQuery('SELECT COUNT(*) AS count FROM $tableAuthors');
    return categoriesCount.first['count'] == 0 && authorsCount.first['count'] == 0;
  }

  // Check if the local database exists
  Future<bool> localDatabaseExists() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return File(path).exists();
  }

  static Future<Map<String, dynamic>> fetchAppSettings() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('app')
          .doc('appSettings')
          .get();

      if (snapshot.exists) {
        return {
          'appName': snapshot.data()!['appName'] ?? '',
          'fontFamily': snapshot.data()!['fontFamily'] ?? 'Roboto',
          'fontSize': snapshot.data()!['fontSize'] ?? 24.0,
          'privacyPolicyUrl': snapshot.data()!['privacyPolicyUrl'] ?? '',
          'termsOfServiceUrl': snapshot.data()!['termsOfServiceUrl'] ?? '',
          'upgradeCopy': snapshot.data()!['upgradeCopy'] ?? '',
          'thankyouCopy': snapshot.data()!['thankyouCopy'] ?? '',
          'productId': snapshot.data()!['productId'] ?? '',
        };
      } else {
        return {
          'appName': '',
          'fontFamily': 'Roboto',
          'fontSize': 24.0,
          'privacyPolicyUrl': '',
          'termsOfServiceUrl': '',
          'upgradeCopy': '',
          'thankyouCopy': '',
          'productId': '',
        };
      }
    } catch (error) {
      print("Failed to fetch app settings: $error");
      return {
        'appName': '',
        'fontFamily': 'Roboto',
        'fontSize': 24.0,
        'privacyPolicyUrl': '',
        'termsOfServiceUrl': '',
        'upgradeCopy': '',
        'thankyouCopy': '',
        'productId': '',
      };
    }
  }

  // Add this method to your DatabaseHelper class
  Future<List<Map<String, dynamic>>> queryAllRows({required String table}) async {
    final db = await instance.database;
    String query;

    switch (table) {
      case 'authors':
        query = 'SELECT * FROM authors';
        break;
      case 'categories':
        query = 'SELECT * FROM categories';
        break;
      case 'cultures':
        query = 'SELECT * FROM cultures';
        break;
      case 'author_content':
        query = '''
          SELECT author_content.id, author_content.content, authors.name as author
          FROM author_content
          JOIN authors ON author_content.author_id = authors.id
        ''';
        break;
      case 'category_content':
        query = '''
          SELECT category_content.id, category_content.content, categories.name as category
          FROM category_content
          JOIN categories ON category_content.category_id = categories.id
        ''';
        break;
      case 'culture_content':
        query = '''
          SELECT culture_content.id, culture_content.content, cultures.name as culture
          FROM culture_content
          JOIN cultures ON culture_content.culture_id = cultures.id
        ''';
        break;
      default:
        throw Exception('Invalid table name');
    }

    return await db.rawQuery(query);
  }


  Future<String?> getAuthorImagePath(String authorId) async {
    final db = await database;
    String? imageLocalPath;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT image_remote
      FROM authors
      WHERE id = ?
    ''', [authorId]);

    if (result.isNotEmpty) {
      imageLocalPath = result.first['image_local'];
    }
   // print('Author ID in DB: $authorId');
   // print('Author Image path from DB: $imageLocalPath');
    return imageLocalPath;
  }

  // Define _downloadImage method outside of syncFirestoreData
  Future<String?> _downloadImage(String imageUrl) async {
  //  print('Downloading image from $imageUrl...');
    final fileName = basename(imageUrl);
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = join(directory.path, fileName);

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await File(imagePath).writeAsBytes(response.bodyBytes);
       // print('Image downloaded from $imageUrl');
        return imagePath;
      } else {
       // print('Failed to download image: $imageUrl');
        return null;
      }
    } catch (e) {
     // print('Error downloading image: $imageUrl - $e');
      return null;
    }
  }

  Future<String?> _downloadImageWithRetry(String url, {int retries = 3, Duration delayBetweenRetries = const Duration(seconds: 3)}) async {
    if (retries <= 0) {
      return null;
    }

    try {
      final String? imagePath = await _downloadImage(url);
      return imagePath;
    } catch (e) {
    //  print('Download failed. Retrying...');
      await Future.delayed(delayBetweenRetries);
      return await _downloadImageWithRetry(url, retries: retries - 1, delayBetweenRetries: delayBetweenRetries);
    }
  }



  Future<void> upsert(String tableName, Map<String, dynamic> data, String primaryKeyColumn, dynamic primaryKeyValue) async {
    final Database db = await instance.database;
    await db.transaction((txn) async {
      // Check if the entry already exists
      final existingEntry = await txn.query(tableName, where: '$primaryKeyColumn = ?', whereArgs: [primaryKeyValue]);

      if (existingEntry.isNotEmpty) {
        // Update the existing entry
        await txn.update(tableName, data, where: '$primaryKeyColumn = ?', whereArgs: [primaryKeyValue]);
      } else {
        // Insert a new entry
        await txn.insert(tableName, data);
      }
    });
  }

  Future<void> checkForUpdates() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;

    await db.transaction((txn) async {

      // Check for new categories
      QuerySnapshot categoriesSnapshot = await firestore.collection(tableCategories).get();
      for (var category in categoriesSnapshot.docs) {
        Map<String, dynamic> categoryData = category.data() as Map<String, dynamic>;
        String categoryId = category.id;
        int remoteTimestamp = (categoryData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;

        List<Map<String, dynamic>> localData = await txn.query(tableCategories, where: 'id = ?', whereArgs: [categoryId]);
        if (localData.isEmpty || localData.first['timestamp'] < remoteTimestamp) {
          // If the category is not in the local database or the remote timestamp is newer, insert or update the local data
          await syncFirestoreCategory(categoryId, convertTimestamps(categoryData));
        }
      }

      // Check for new authors
      QuerySnapshot authorsSnapshot = await firestore.collection(tableAuthors).get();
      for (var author in authorsSnapshot.docs) {
        Map<String, dynamic> authorData = author.data() as Map<String, dynamic>;
        String authorId = author.id;
        int remoteTimestamp = (authorData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;

        List<Map<String, dynamic>> localData = await txn.query(tableAuthors, where: 'id = ?', whereArgs: [authorId]);
        if (localData.isEmpty || localData.first['timestamp'] < remoteTimestamp) {
          // If the author is not in the local database or the remote timestamp is newer, insert or update the local data
          await syncFirestoreAuthor(authorId, convertTimestamps(authorData));
        }
      }

      // Check for new category content
      QuerySnapshot categoryContentSnapshot = await firestore.collection(tableCategoryContent).get();
      for (var content in categoryContentSnapshot.docs) {
        Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
        String contentId = content.id;
        int remoteTimestamp = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;

        List<Map<String, dynamic>> localData = await txn.query(tableCategoryContent, where: 'id = ?', whereArgs: [contentId]);
        if (localData.isEmpty || localData.first['timestamp'] < remoteTimestamp) {
          // If the category content is not in the local database or the remote timestamp is newer, insert or update the local data
          await syncFirestoreCategoryContent(contentId, convertTimestamps(contentData));
        }
      }

      // Check for new author content
      QuerySnapshot authorContentSnapshot = await firestore.collection(tableAuthorContent).get();
      for (var content in authorContentSnapshot.docs) {
        Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
        String contentId = content.id;
        int remoteTimestamp = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;

        List<Map<String, dynamic>> localData = await txn.query(tableAuthorContent, where: 'id = ?', whereArgs: [contentId]);
        if (localData.isEmpty || localData.first['timestamp'] < remoteTimestamp) {
          // If the author content is not in the local database or the remote timestamp is newer, insert or update the local data
          await syncFirestoreAuthorContent(contentId, convertTimestamps(contentData));
        }
      }


    });
  }

  Future<void> syncFirestoreCategory(String categoryId, Map<String, dynamic> categoryData) async {
    // Download category icon
    if (categoryData['icon_remote'] != null) {
      final iconPath = await _downloadImageWithRetry(categoryData['icon_remote']);
      if (iconPath != null) {
        categoryData['icon_local'] = iconPath;
      }
    }
    await upsert(tableCategories, convertTimestamps(categoryData), 'id', categoryId);
  }

  Future<void> syncFirestoreAuthor(String authorId, Map<String, dynamic> authorData) async {
    // Download author image
    if (authorData['image_remote'] != null) {
      final imagePath = await _downloadImageWithRetry(authorData['image_remote']);
      if (imagePath != null) {
        authorData['image_local'] = imagePath;
      }
    }
    await upsert(tableAuthors, convertTimestamps(authorData), 'id', authorId);
  }

  Future<void> syncFirestoreCategoryContent(String contentId, Map<String, dynamic> contentData) async {
    await upsert(tableCategoryContent, convertTimestamps(contentData), 'id', contentId);
  }

  Future<void> syncFirestoreAuthorContent(String contentId, Map<String, dynamic> contentData) async {
    await upsert(tableAuthorContent, convertTimestamps(contentData), 'id', contentId);
  }

  // Add a method to clear and recreate the local database
  Future<void> recreateDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('DELETE FROM $tableCategories');
      await txn.execute('DELETE FROM $tableAuthors');
      await txn.execute('DELETE FROM $tableCategoryContent');
      await txn.execute('DELETE FROM $tableAuthorContent');
      await txn.execute('DELETE FROM $tableCultures');
      await txn.execute('DELETE FROM $tableCultureContent');
      await txn.execute('DELETE FROM $tableBackgroundImages');
      await txn.execute('DELETE FROM $tableDevices');
      await txn.execute('DELETE FROM $tableDeviceFavoriteContent');
      await txn.execute('DELETE FROM $tableNotifications');
    });
    //await syncFirestoreData();
  }


  Map<String, dynamic> convertTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is Timestamp) {
        data[key] = value.toDate().millisecondsSinceEpoch;
      }
    });
    return data;
  }

  // Insert a row into a table
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    int result = 0;

    await db.transaction((txn) async {
      result = await txn.insert(
        table,
        convertTimestamps(data),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return result;
  }

  Future<void> syncFirestoreData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Future<void> updateImagePath(String table, String id, String imagePath, String imageField) async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.update(
          table,
          {imageField: imagePath},
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    }

    final db = await database;

    // Synchronize categories
    List<Future<void>> categoryFutures = [];
    QuerySnapshot categoriesSnapshot = await firestore.collection(tableCategories).get();
    for (var category in categoriesSnapshot.docs) {
      categoryFutures.add(() async {
        Map<String, dynamic> categoryData = category.data() as Map<String, dynamic>;
        categoryData['id'] = category.id;
        // Download author image
        //if (categoryData['icon_remote'] != null) {
         // final iconPath = await _downloadImageWithRetry(categoryData['icon_remote']);
         // if (iconPath != null) {
         //   categoryData['icon_local'] = iconPath;
        //  }
        //}
        await db.transaction((txn) async {
          await txn.insert(
            tableCategories,
            convertTimestamps(categoryData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(categoryFutures);

    // Synchronize authors
    List<Future<void>> authorFutures = [];
    QuerySnapshot authorsSnapshot = await firestore.collection(tableAuthors).get();
    for (var author in authorsSnapshot.docs) {
      authorFutures.add(() async {
        Map<String, dynamic> authorData = author.data() as Map<String, dynamic>;
        authorData['id'] = author.id;
        // Download author image
       // if (authorData['image_remote'] != null) {
        //  final imagePath = await _downloadImageWithRetry(authorData['image_remote']);
       //   if (imagePath != null) {
        //    authorData['image_local'] = imagePath;
       //   }
      //  }
        await db.transaction((txn) async {
          await txn.insert(
            tableAuthors,
            convertTimestamps(authorData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(authorFutures);

    // Synchronize cultures
    List<Future<void>> cultureFutures = [];
    QuerySnapshot culturesSnapshot = await firestore.collection(tableCultures).get();
    for (var culture in culturesSnapshot.docs) {
      cultureFutures.add(() async {
        Map<String, dynamic> cultureData = culture.data() as Map<String, dynamic>;
        cultureData['id'] = culture.id;
        await db.transaction((txn) async {
          await txn.insert(
            tableCultures,
            convertTimestamps(cultureData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(cultureFutures);

    // Synchronize category_quotes
    List<Future<void>> categoryContentFutures = [];
    QuerySnapshot categoryContentSnapshot = await firestore.collection(tableCategoryContent).get();
    for (var content in categoryContentSnapshot.docs) {
      categoryContentFutures.add(() async {
        Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
        contentData['id'] = content.id;
        // Convert Timestamp to DateTime in milliseconds since the Unix epoch
        contentData['timestamp'] = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
        await db.transaction((txn) async {
          await txn.insert(
            tableCategoryContent,
            convertTimestamps(contentData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(categoryContentFutures);

    // Synchronize author_content
    List<Future<void>> authorContentFutures = [];
    QuerySnapshot authorContentSnapshot = await firestore.collection(tableAuthorContent).get();
    for (var content in authorContentSnapshot.docs) {
      authorContentFutures.add(() async {
        Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
        contentData['id'] = content.id;
        // Convert Timestamp to DateTime in milliseconds since the Unix epoch
        contentData['timestamp'] = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
        await db.transaction((txn) async {
          await txn.insert(
            tableAuthorContent,
            convertTimestamps(contentData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(authorContentFutures);

    // Synchronize culture_quotes
    List<Future<void>> cultureContentFutures = [];
    QuerySnapshot cultureContentSnapshot = await firestore.collection(tableCultureContent).get();
    for (var content in cultureContentSnapshot.docs) {
      cultureContentFutures.add(() async {
        Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
        contentData['id'] = content.id;
        // Convert Timestamp to DateTime in milliseconds since the Unix epoch
        contentData['timestamp'] = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
        await db.transaction((txn) async {
          await txn.insert(
            tableCultureContent,
            convertTimestamps(contentData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(cultureContentFutures);

    // Synchronize background_images
    List<Future<void>> backgroundImagesFutures = [];
    QuerySnapshot backgroundImagesSnapshot = await firestore.collection(tableBackgroundImages).get();
    for (var backgroundImage in backgroundImagesSnapshot.docs) {
      backgroundImagesFutures.add(() async {
        Map<String, dynamic> backgroundImageData = backgroundImage.data() as Map<String, dynamic>;
        backgroundImageData['id'] = backgroundImage.id;
        // Download background image
        //if (backgroundImageData['back_img_remote_url'] != null) {
        //  final backImgLocalUrl = await _downloadImageWithRetry(backgroundImageData['back_img_remote_url']);
        //  if (backImgLocalUrl != null) {
        //    backgroundImageData['back_img_local_url'] = backImgLocalUrl;
         // }
       // }
        await db.transaction((txn) async {
          await txn.insert(
            tableBackgroundImages,
            convertTimestamps(backgroundImageData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(backgroundImagesFutures);

    // Synchronize device_favorite_quotes
    List<Future<void>> deviceFavoriteContentFutures = [];
    QuerySnapshot deviceFavoriteContentSnapshot = await firestore.collection(tableDeviceFavoriteContent).get();
    for (var favoriteContent in deviceFavoriteContentSnapshot.docs) {
      deviceFavoriteContentFutures.add(() async {
        Map<String, dynamic> favoriteContentData = favoriteContent.data() as Map<String, dynamic>;
        favoriteContentData['id'] = favoriteContent.id;
        // Convert Timestamp to DateTime in milliseconds since the Unix epoch
        favoriteContentData['timestamp'] = (favoriteContentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
        await db.transaction((txn) async {
          await txn.insert(
            tableDeviceFavoriteContent,
            convertTimestamps(favoriteContentData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(deviceFavoriteContentFutures);
  }

  Future<void> fetchEssentialData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;

    // Fetch categories
    List<Future<void>> categoryFutures = [];
    QuerySnapshot categoriesSnapshot = await firestore.collection(tableCategories).get();
    for (var category in categoriesSnapshot.docs) {
      categoryFutures.add(() async {
        Map<String, dynamic> categoryData = category.data() as Map<String, dynamic>;
        categoryData['id'] = category.id;
        await db.transaction((txn) async {
          await txn.insert(
            tableCategories,
            convertTimestamps(categoryData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(categoryFutures);

    // Fetch cultures
    List<Future<void>> cultureFutures = [];
    QuerySnapshot culturesSnapshot = await firestore.collection(tableCultures).get();
    for (var culture in culturesSnapshot.docs) {
      cultureFutures.add(() async {
        Map<String, dynamic> cultureData = culture.data() as Map<String, dynamic>;
        cultureData['id'] = culture.id;
        await db.transaction((txn) async {
          await txn.insert(
            tableCultures,
            convertTimestamps(cultureData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(cultureFutures);
  }

  Future<void> syncBackgroundImagesIfNeeded() async {
    final db = await database;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Check if there are any entries in the background_images table
    List<Map<String, dynamic>> rows = await db.query(tableBackgroundImages);
    if (rows.isEmpty) {
      // If the table is empty, synchronize background images
      QuerySnapshot backgroundImagesSnapshot = await firestore.collection(tableBackgroundImages).get();
      for (var backgroundImage in backgroundImagesSnapshot.docs) {
        Map<String, dynamic> backgroundImageData = backgroundImage.data() as Map<String, dynamic>;
        backgroundImageData['id'] = backgroundImage.id;

        // Download background image
      /*  if (backgroundImageData['back_img_remote_url'] != null) {
          final backImgRemoteUrl = backgroundImageData['back_img_remote_url'];
          final backImgLocalUrl = await downloadAndSaveImage(backImgRemoteUrl, 'background_image_${backgroundImage['id']}');
          if (backImgLocalUrl != null) {
            // Remove query parameters and URL decode the remaining path
            final decodedBackImgLocalUrl = Uri.decodeFull(Uri.parse(backImgLocalUrl).path);

            backgroundImageData['back_img_local_url'] = decodedBackImgLocalUrl;
          }
        }
      */
        await db.transaction((txn) async {
          await txn.insert(
            tableBackgroundImages,
            convertTimestamps(backgroundImageData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }
    }
  }


  // In your DatabaseHelper class

// Method to check if the favorites table is empty
  Future<bool> isFavoritesEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableDeviceFavoriteContent'));
    return count == 0;
  }

// Method to sync favorite content from Firestore
  Future<void> syncFavoriteContent() async {
    final db = await database;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    List<Future<void>> favoriteContentFutures = [];
    QuerySnapshot favoriteContentSnapshot = await firestore.collection(tableDeviceFavoriteContent).get();
    for (var favoriteContent in favoriteContentSnapshot.docs) {
      favoriteContentFutures.add(() async {
        Map<String, dynamic> favoriteContentData = favoriteContent.data() as Map<String, dynamic>;
        favoriteContentData['id'] = favoriteContent.id;
        // Convert Timestamp to DateTime in milliseconds since the Unix epoch
        if (favoriteContentData['timestamp'] is Timestamp) {
          favoriteContentData['timestamp'] = (favoriteContentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
        }
        if (favoriteContentData['last_updated'] is Timestamp) {
          favoriteContentData['last_updated'] = (favoriteContentData['last_updated'] as Timestamp).toDate().millisecondsSinceEpoch;
        }
        await db.transaction((txn) async {
          await txn.insert(
            tableDeviceFavoriteContent,
            convertTimestamps(favoriteContentData),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
      }());
    }
    await Future.wait(favoriteContentFutures);
  }


  Future<int> getContentCountByCategory(String categoryId) async {
    final db = await database;
    String query = '''
    SELECT COUNT(*)
    FROM $tableCategoryContent
    WHERE category_id = ?
    ''';
    List<Map<String, dynamic>> result = await db.rawQuery(query, [categoryId]);
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  Future<int> getContentCountByAuthor(String authorId) async {
    final db = await database;
    String query = '''
    SELECT COUNT(*)
    FROM $tableAuthorContent
    WHERE author_id = ?
    ''';
    List<Map<String, dynamic>> result = await db.rawQuery(query, [authorId]);
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  Future<int> getContentCountByCulture(String cultureId) async {
    final db = await database;
    String query = '''
    SELECT COUNT(*)
    FROM $tableCultureContent
    WHERE culture_id = ?
    ''';
    List<Map<String, dynamic>> result = await db.rawQuery(query, [cultureId]);
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }


// Update getContentByAuthor to fetch from author_content table
  Future<List<Map<String, dynamic>>> getContentByAuthor(String authorId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int localContentCount = await getContentCountByAuthor(authorId);

    // Clear the cached count when the app starts
    bool isAppRestarted = prefs.getBool('app_restarted') ?? true;
    if (isAppRestarted) {
      prefs.remove('firestore_content_count_author_$authorId');
      prefs.setBool('app_restarted', false);
    }

    int firestoreContentCount = prefs.getInt('firestore_content_count_$authorId') ?? 0;
  //  print('Cached Firestore Content Count: $firestoreContentCount');

    // Check if online connectivity is available
    bool online = await isOnline();

    // If the count is not cached or the app is restarted, fetch the count from Firestore
    if (firestoreContentCount == 0 || isAppRestarted) {
      if (online) {
        QuerySnapshot authorContentSnapshot = await firestore
            .collection(tableAuthorContent)
            .where('author_id', isEqualTo: authorId)
            .get();

        firestoreContentCount = authorContentSnapshot.docs.length;
        prefs.setInt('firestore_content_count_author_$authorId', firestoreContentCount);
     //   print('Fetched Firestore Content Count: $firestoreContentCount');
      }
    }

    // If local content are fewer than content from Firestore and online, fetch from Firestore and sync to SQLite
    Set<String> syncedAuthorIds = prefs.getStringList('synced_author_ids')?.toSet() ?? {};
    if (localContentCount < firestoreContentCount && online && !syncedAuthorIds.contains(authorId)) {
      await fetchAndSyncAuthorContent(authorId);
    }

    String query = '''
    SELECT $tableAuthorContent.*, $tableAuthors.image_remote
    FROM $tableAuthorContent
    JOIN $tableAuthors ON $tableAuthorContent.author_id = $tableAuthors.id
    WHERE $tableAuthorContent.author_id = ?
    ORDER BY $tableAuthorContent.timestamp DESC
  ''';

    List<Map<String, dynamic>> content = await db.rawQuery(query, [authorId]);

    return content;
  }

  Future<List<Map<String, dynamic>>> getContentByCategory(String categoryId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int localContentCount = await getContentCountByCategory(categoryId);

    // Clear the cached count when the app starts
    bool isAppRestarted = prefs.getBool('app_restarted') ?? true;
    if (isAppRestarted) {
      prefs.remove('firestore_content_count_category_$categoryId');
      prefs.setBool('app_restarted', false);
    }

    int firestoreContentCount = prefs.getInt('firestore_content_count_$categoryId') ?? 0;

    // Check if online connectivity is available
    bool online = await isOnline();

    // If the count is not cached or the app is restarted, fetch the count from Firestore
    if (firestoreContentCount == 0 || isAppRestarted) {
      if (online) {
        QuerySnapshot categoryContentSnapshot = await firestore
            .collection(tableCategoryContent)
            .where('category_id', isEqualTo: categoryId)
            .get();

        firestoreContentCount = categoryContentSnapshot.docs.length;
        prefs.setInt('firestore_content_count_category_$categoryId', firestoreContentCount);
      }
    }

    // If local content are fewer than content from Firestore and online, fetch from Firestore and sync to SQLite
    Set<String> syncedCategoryIds = prefs.getStringList('synced_category_ids')?.toSet() ?? {};
    if (localContentCount < firestoreContentCount && online && !syncedCategoryIds.contains(categoryId)) {
      await fetchAndSyncCategoryContent(categoryId);
    }

    List<Map<String, dynamic>> content = await db.query(
      tableCategoryContent,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'timestamp DESC',
    );

    return content;
  }

  Future<List<Map<String, dynamic>>> queryAllCultures({int? limit, int? offset}) async {
    final db = await database;
    return await db.query(
      tableCultures,
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getContentByCulture(String cultureId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int localContentCount = await getContentCountByCulture(cultureId);

    // Clear the cached count when the app starts
    bool isAppRestarted = prefs.getBool('app_restarted') ?? true;
    if (isAppRestarted) {
      prefs.remove('firestore_content_count_culture_$cultureId');
      prefs.setBool('app_restarted', false);
    }

    int firestoreContentCount = prefs.getInt('firestore_content_count_$cultureId') ?? 0;

    // Check if online connectivity is available
    bool online = await isOnline();

    // If the count is not cached or the app is restarted, fetch the count from Firestore
    if (firestoreContentCount == 0 || isAppRestarted) {
      if (online) {
        QuerySnapshot cultureQuotesSnapshot = await firestore
            .collection(tableCultureContent)
            .where('culture_id', isEqualTo: cultureId)
            .get();

        firestoreContentCount = cultureQuotesSnapshot.docs.length;
        prefs.setInt('firestore_content_count_culture_$cultureId', firestoreContentCount);
      }
    }

    // If local content are fewer than content from Firestore, fetch from Firestore and sync to SQLite
    Set<String> syncedCultureIds = prefs.getStringList('synced_culture_ids')?.toSet() ?? {};
    if (localContentCount < firestoreContentCount && online && !syncedCultureIds.contains(cultureId)) {
      await fetchAndSyncCultureContent(cultureId);
    }

    String query = '''
    SELECT $tableCultureContent.*, $tableCultures.image_remote
    FROM $tableCultureContent
    JOIN $tableCultures ON $tableCultureContent.culture_id = $tableCultures.id
    WHERE $tableCultureContent.culture_id = ?
    ORDER BY $tableCultureContent.timestamp DESC
  ''';

    List<Map<String, dynamic>> content = await db.rawQuery(query, [cultureId]);

    return content;
  }


  Future<void> fetchAndSyncAuthorContent(String authorId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    QuerySnapshot authorContentSnapshot = await firestore
        .collection(tableAuthorContent)
        .where('author_id', isEqualTo: authorId)
        .get();

    for (var content in authorContentSnapshot.docs) {
      Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
      contentData['id'] = content.id;
      contentData['timestamp'] = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        await txn.insert(
          tableAuthorContent,
          convertTimestamps(contentData),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    }

    // After the sync operation, add this author ID to the set of synced author IDs
    Set<String> syncedAuthorIds = prefs.getStringList('synced_author_ids')?.toSet() ?? {};
    syncedAuthorIds.add(authorId);
    await prefs.setStringList('synced_author_ids', syncedAuthorIds.toList());
  }

  Future<void> fetchAndSyncCategoryContent(String categoryId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    QuerySnapshot categoryContentSnapshot = await firestore
        .collection(tableCategoryContent)
        .where('category_id', isEqualTo: categoryId)
        .get();

    for (var content in categoryContentSnapshot.docs) {
      Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
      contentData['id'] = content.id;
      contentData['timestamp'] = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        await txn.insert(
          tableCategoryContent,
          convertTimestamps(contentData),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    }

    // After the sync operation, add this category ID to the set of synced category IDs
    Set<String> syncedCategoryIds = prefs.getStringList('synced_category_ids')?.toSet() ?? {};
    syncedCategoryIds.add(categoryId);
    await prefs.setStringList('synced_category_ids', syncedCategoryIds.toList());
  }

  Future<void> fetchAndSyncCultureContent(String cultureId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    QuerySnapshot cultureContentSnapshot = await firestore
        .collection(tableCultureContent)
        .where('culture_id', isEqualTo: cultureId)
        .get();

    for (var content in cultureContentSnapshot.docs) {
      Map<String, dynamic> contentData = content.data() as Map<String, dynamic>;
      contentData['id'] = content.id;
      contentData['timestamp'] = (contentData['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
      await db.transaction((txn) async {
        await txn.insert(
          tableCultureContent,
          convertTimestamps(contentData),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    }

    // After the sync operation, add this culture ID to the set of synced culture IDs
    Set<String> syncedCultureIds = prefs.getStringList('synced_culture_ids')?.toSet() ?? {};
    syncedCultureIds.add(cultureId);
    await prefs.setStringList('synced_culture_ids', syncedCultureIds.toList());
  }


  // Query all categories
  Future<List<Map<String, dynamic>>> queryAllCategories() async {
    final db = await database;
    return await db.query(tableCategories, orderBy: 'name');
  }

  Future<List<Map<String, dynamic>>> queryAuthorContent(String authorId) async {
    final db = await database;
    return await db.query('author_content', where: 'author_id = ?', whereArgs: [authorId], orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> queryCategoryContent(String categoryId) async {
    final db = await database;
    return await db.query('category_content', where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> queryCultureContent(String cultureId) async {
    final db = await database;
    return await db.query('culture_content', where: 'category_id = ?', whereArgs: [cultureId], orderBy: 'timestamp DESC');
  }


  //Future<List<Map<String, dynamic>>> queryAllAuthors() async {
    //final db = await database;
  //  return await db.query(tableAuthors, orderBy: 'name');
 // }

  Future<List<Map<String, dynamic>>> queryAllAuthors({int? limit, int? offset}) async {
    final db = await database;
    return await db.query(
      tableAuthors,
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
  }


  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.id ?? 'default_android_id';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'default_ios_id';
    } else {
      throw Exception('Unsupported platform');
    }
  }

  Future<bool> isContentInDeviceFavorites(String contentId) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final result = await db.query(
      tableDeviceFavoriteContent,
      where: 'user_id = ? AND content_id = ?',
      whereArgs: [userId, contentId],
    );
    return result.isNotEmpty;
  }

  final Map<String, ValueNotifier<bool>> _favoriteContentNotifiers = {};

  ValueNotifier<bool> isContentFavoriteNotifier(String contentId) {
    if (!_favoriteContentNotifiers.containsKey(contentId)) {
      _favoriteContentNotifiers[contentId] = ValueNotifier<bool>(false);
      isContentInDeviceFavorites(contentId).then((isFavorite) {
        _favoriteContentNotifiers[contentId]?.value = isFavorite;
      });
    }
    return _favoriteContentNotifiers[contentId]!;
  }

  void updateContentFavoriteNotifier(String contentId) async {
    if (!_favoriteContentNotifiers.containsKey(contentId)) {
      _favoriteContentNotifiers[contentId] = ValueNotifier<bool>(false);
    }
    // Ensure that the current value of the notifier is updated with the opposite of the current value
    _favoriteContentNotifiers[contentId]?.value = !(await isContentInDeviceFavorites(contentId));
  }


  Future<int> addToDeviceFavorites(String contentId) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;

    // Create a unique ID using the userId and quoteId combination
    String uniqueId = '$userId-$contentId';

    // Check if there is an existing favorite with the same content ID for the user ID
    List<Map<String, dynamic>> existingFavorites = await db.query(
      'user_favorites',
      where: 'content_id = ? AND user_id = ?',
      whereArgs: [contentId, userId],
    );

    int result;

    if (existingFavorites.isNotEmpty) {
      // Update the favorite_status to 1 in SQLite
      result = await db.update(
        'user_favorites',
        {
          'favorite_status': 1,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'content_id = ? AND user_id = ?',
        whereArgs: [contentId, userId],
      );
    } else {
      // Insert a new favorite with favorite_status set to 1
      result = await db.insert(
        'user_favorites',
        {
          'favorite_status': 1,
          'id': uniqueId,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
          'content_id': contentId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Update Firestore
    if (await isOnline()) {
      int retries = 3;
      bool success = false;
      while (!success && retries > 0) {
        try {
          await FirebaseFirestore.instance
              .collection('user_favorites')
              .doc(uniqueId)
              .set({
            'favorite_status': 1,
            'id': uniqueId,
            'last_updated': DateTime.now().millisecondsSinceEpoch,
            'content_id': contentId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'user_id': userId,
          });
          success = true;
        } catch (e) {
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
      if (!success) {
        // Handle the case when all retries fail
      }
    }

    return result;
  }

  Future<int> removeFromDeviceFavorites(String contentId) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    int result = await db.update(
      'user_favorites',
      {
        'favorite_status': 0,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'content_id = ? AND user_id = ?',
      whereArgs: [contentId, userId],
    );

    // Update Firestore
    if (await isOnline()) {
      int retries = 3;
      bool success = false;
      while (!success && retries > 0) {
        try {
          await FirebaseFirestore.instance
              .collection('user_favorites')
              .doc('$userId-$contentId')
              .update({
            'favorite_status': 0,
            'last_updated': DateTime.now().millisecondsSinceEpoch,
          });
          success = true;
        } catch (e) {
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
      if (!success) {
        // Handle the case when all retries fail
      }
    }

    return result;
  }


  Future<List<Map<String, dynamic>>> getUserFavoriteContentWithAuthorAndCategory({String? authorId, String? categoryId}) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;

    String query = '''
    SELECT q.*, a.name as author, c.name as category, uf.favorite_status
    FROM (
      SELECT id, content, author_id, NULL as category_id, timestamp FROM author_content
      UNION ALL
      SELECT id, content, NULL as author_id, category_id, timestamp FROM category_content
    ) q
    LEFT JOIN authors a ON q.author_id = a.id
    LEFT JOIN categories c ON q.category_id = c.id
    INNER JOIN user_favorites uf ON q.id = uf.content_id AND uf.user_id = ?
  ''';

    List<dynamic> arguments = [userId];

    if (authorId != null) {
      query += ' WHERE q.author_id = ?';
      arguments.add(authorId);
    } else if (categoryId != null) {
      query += ' WHERE q.category_id = ?';
      arguments.add(categoryId);
    }

    final List<Map<String, dynamic>> res = await db.rawQuery(query, arguments);
    return res;
  }


  Future<List<Map<String, dynamic>>> queryAllDeviceFavoriteContent() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    List<Map<String, dynamic>> rawData = await db.rawQuery('''
SELECT combined_content.* FROM (
  SELECT * FROM $tableAuthorContent
  UNION ALL
  SELECT * FROM $tableCategoryContent
  UNION ALL
  SELECT * FROM $tableCultureContent
) AS combined_content
JOIN $tableDeviceFavoriteContent ON combined_content.id = $tableDeviceFavoriteContent.content_id
WHERE $tableDeviceFavoriteContent.user_id = ? AND $tableDeviceFavoriteContent.favorite_status = 1
ORDER BY $tableDeviceFavoriteContent.last_updated DESC
''', [userId]);
   // print('Raw data fetched from SQLite: $rawData');
    return rawData;
  }

  Future<List<Map<String, dynamic>>> querySearchAllDeviceFavoriteContent(String searchQuery) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;

    // Update the SQL query to include the search condition
    List<Map<String, dynamic>> rawData = await db.rawQuery('''
    SELECT combined_content.* FROM (
      SELECT * FROM $tableAuthorContent
      UNION ALL
      SELECT * FROM $tableCategoryContent
      UNION ALL
      SELECT * FROM $tableCultureContent
    ) AS combined_content
    JOIN $tableDeviceFavoriteContent ON combined_content.id = $tableDeviceFavoriteContent.content_id
    WHERE $tableDeviceFavoriteContent.user_id = ? 
      AND $tableDeviceFavoriteContent.favorite_status = 1
      AND combined_content.content_text LIKE ?
    ORDER BY $tableDeviceFavoriteContent.last_updated DESC
  ''', [userId, '%$searchQuery%']);

  //  print('Raw data fetched from SQLite: $rawData');
    return rawData;
  }




// isQuoteInFavorites method
  Future<bool> isContentInFavorites(int contentId) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final result = await db.query(
      tableDeviceFavoriteContent,
      where: 'content_id = ? AND user_id = ? AND favorite_status = 1',
      whereArgs: [contentId, userId],
    );
    return result.isNotEmpty;
  }


// Query categories by search query
  Future<List<Map<String, dynamic>>> queryCategories(String query) async {
    final db = await database;
    return await db.query(
      tableCategories,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name',
    );
  }

  Future<List<Map<String, dynamic>>> queryAuthors(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> authors = await db.query(
      tableAuthors,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return authors;
  }

  Future<List<Map<String, dynamic>>> queryCultures(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> cultures = await db.query(
      tableCultures,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return cultures;
  }

  Future<List<Map<String, dynamic>>> queryFavorites(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> cultures = await db.query(
      tableDeviceFavoriteContent,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return cultures;
  }


  // Query categories by search query
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    final db = await database;
    return await db.query(
        'categories',
        where: 'name LIKE ?',
        whereArgs: ['%$query%']
    );
  }

  Future<List<Map<String, dynamic>>> queryAllQuotes(String query) async {
    final db = await database;
    final searchString = '%$query%';

    final result = await db.rawQuery('''
    SELECT author_content.id, author_content.content, authors.name as author, categories.name as category
    FROM author_content
    INNER JOIN category_content ON author_content.id = category_content.id
    INNER JOIN authors ON author_content.content_id = authors.id
    INNER JOIN categories ON category_content.category_id = categories.id
    WHERE author_content.content LIKE ? OR authors.name LIKE ? OR categories.name LIKE ?
    GROUP BY author_content.id
  ''', [searchString, searchString, searchString]);

    return result;
  }

// Add this method to get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    return await queryAllCategories();
  }

// Add this method to get all favorite content
  Future<List<Map<String, dynamic>>> getDeviceFavoriteContent({String? author, String? category}) async {
    List<Map<String, dynamic>> favoriteContent = await queryAllDeviceFavoriteContent();

    if (author != null && author.isNotEmpty) {
      favoriteContent = favoriteContent.where((content) => content['author'].toString().toLowerCase().contains(author.toLowerCase())).toList();
    }

    if (category != null && category.isNotEmpty) {
      favoriteContent = favoriteContent.where((content) => content['category'].toString().toLowerCase().contains(category.toLowerCase())).toList();
    }

    return favoriteContent;
  }

  Future<List<Map<String, dynamic>>> getDistinctAuthorsInFavorites() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
  SELECT DISTINCT a.id, a.name
  FROM user_favorites dfq
  JOIN author_content aq ON dfq.content_id = aq.id
  JOIN authors a ON aq.author_id = a.id
  WHERE dfq.user_id = ? AND dfq.favorite_status = 1
''', [userId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getDistinctCategoriesInFavorites() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
  SELECT DISTINCT c.id, c.name
  FROM user_favorites dfq
  JOIN category_content cq ON dfq.content_id = cq.id
  JOIN categories c ON cq.category_id = c.id
  WHERE dfq.user_id = ? AND dfq.favorite_status = 1
''', [userId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getDistinctCulturesInFavorites() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
  SELECT DISTINCT cu.id, cu.name
  FROM user_favorites dfq
  JOIN culture_content cuq ON dfq.content_id = cuq.id
  JOIN cultures cu ON cuq.culture_id = cu.id
  WHERE dfq.user_id = ? AND dfq.favorite_status = 1
''', [userId]);
    return result;
  }


  Future<void> printAllUserFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM user_favorites');
  //  print("User favorites: $result");
  }


  Future<List<Map<String, dynamic>>> getDeviceFavoriteContentWithAuthorAndCategoryAndCulture({String? authorId, String? categoryId, String? cultureId}) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
   // print("User ID: $userId");
   // printAllUserFavorites();
    final db = await database;
    String query = '''
SELECT dfq.content_id, q.content, a.name as author, a.image_remote as author_image, c.name as category, cu.name as culture, a.id as author_id, c.id as category_id, cu.id as culture_id
FROM user_favorites dfq
JOIN (
  SELECT id, content, author_id, null as category_id, null as culture_id
  FROM author_content
  UNION ALL
  SELECT id, content, null as author_id, category_id, null as culture_id
  FROM category_content
  UNION ALL
  SELECT id, content, null as author_id, null as category_id, culture_id
  FROM culture_content
) q ON dfq.content_id = q.id
LEFT JOIN authors a ON q.author_id = a.id
LEFT JOIN categories c ON q.category_id = c.id
LEFT JOIN cultures cu ON q.culture_id = cu.id
WHERE dfq.favorite_status = 1 AND dfq.user_id = ?
''';

    List<dynamic> arguments = [userId];

    if (authorId != null && authorId.isNotEmpty) {
      query += " AND a.id = ?";
      arguments.add(authorId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query += " AND c.id = ?";
      arguments.add(categoryId);
    }

    if (cultureId != null && cultureId.isNotEmpty) {
      query += " AND cu.id = ?";
      arguments.add(cultureId);
    }

    // Add an ORDER BY clause to sort by the created_at field in descending order
    query += " ORDER BY dfq.last_updated DESC";

    final List<Map<String, dynamic>> result = await db.rawQuery(query, arguments);

    // If result is empty, fetch and sync related author, category, and culture content
    if (result.isEmpty) {
      if (authorId != null && authorId.isNotEmpty) {
        await fetchAndSyncAuthorContent(authorId);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        await fetchAndSyncCategoryContent(categoryId);
      }
      if (cultureId != null && cultureId.isNotEmpty) {
        await fetchAndSyncCultureContent(cultureId);
      }

      // Re-run the query after syncing
      return await db.rawQuery(query, arguments);
    }

    return result;
  }


  Future<List<Map<String, dynamic>>> getSearchFavoriteContent(String searchQuery) async {
   // print('Search Query: $searchQuery');
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    String query = '''
    SELECT DISTINCT a.name as author, a.id as author_id, a.image_remote as author_image, c.name as category, c.id as category_id, c.icon_remote as category_icon, cu.name as culture, cu.id as culture_id, cu.image_remote as culture_image
    FROM user_favorites uf
    JOIN (
      SELECT id, author_id, null as category_id, null as culture_id
      FROM author_content
      UNION ALL
      SELECT id, null as author_id, category_id, null as culture_id
      FROM category_content
      UNION ALL
      SELECT id, null as author_id, null as category_id, culture_id
      FROM culture_content
    ) q ON uf.content_id = q.id
    LEFT JOIN authors a ON q.author_id = a.id
    LEFT JOIN categories c ON q.category_id = c.id
    LEFT JOIN cultures cu ON q.culture_id = cu.id
    WHERE uf.favorite_status = 1 AND uf.user_id = ? AND (a.name LIKE ? OR c.name LIKE ? OR cu.name LIKE ?)
    ORDER BY uf.last_updated DESC
  ''';

    List<dynamic> arguments = [
      userId,
      '%$searchQuery%',
      '%$searchQuery%',
      '%$searchQuery%',
    ];

    final List<Map<String, dynamic>> result = await db.rawQuery(query, arguments);

    return result;
  }

  Future<List<Map<String, dynamic>>> getFavoriteContent({String? authorId, String? categoryId}) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;

    String query = """
  SELECT 
    user_favorites.favorite_status,
    user_favorites.last_updated,
    IFNULL(authors.name, categories.name) as name,
    IFNULL(authors.image_remote, categories.icon_remote) as image_remote,
    IFNULL(authors.image_local, categories.icon_local) as image_local,
    IFNULL(author_quotes.content, category_content.content) as content
  FROM user_favorites
  LEFT JOIN author_content ON user_favorites.content_id = author_content.id
  LEFT JOIN category_content ON user_favorites.content_id = category_content.id
  LEFT JOIN authors ON author_content.author_id = authors.id
  LEFT JOIN categories ON category_content.category_id = categories.id
  WHERE user_favorites.user_id = ? AND user_favorites.favorite_status = 1
""";

    List<dynamic> arguments = [userId];

    if (authorId != null) {
      query += " AND authors.id = ?";
      arguments.add(authorId);
    } else if (categoryId != null) {
      query += " AND categories.id = ?";
      arguments.add(categoryId);
    }

    // Execute the query and return the results.
    final List<Map<String, dynamic>> result = await db.rawQuery(query, arguments);
    return result;
  }

  Future<List<Map<String, dynamic>>> getFavoritedAuthors() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final result = await db.rawQuery("""
    SELECT authors.id, authors.name
    FROM authors
    WHERE EXISTS (
      SELECT 1 FROM user_favorites
      JOIN author_content ON user_favorites.content_id = author_content.id
      WHERE user_favorites.user_id = ? AND user_favorites.favorite_status = 1 AND authors.id = author_content.author_id
    )
  """, [userId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getFavoritedCategories() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    final result = await db.rawQuery("""
    SELECT categories.id, categories.name
    FROM categories
    WHERE EXISTS (
      SELECT 1 FROM user_favorites
      JOIN category_content ON user_favorites.content_id = category_content.id
      WHERE user_favorites.user_id = ? AND user_favorites.favorite_status = 1 AND categories.id = category_content.category_id
    )
  """, [userId]);
    return result;
  }


  Future<List<Map<String, dynamic>>> getFavoriteAuthors() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    const String query = """
    SELECT DISTINCT authors.id, authors.name
    FROM user_favorites
    JOIN author_content ON user_favorites.content_id = author_content.id
    JOIN authors ON author_content.author_id = authors.id
    WHERE user_favorites.favorite_status = 1
  """;
    final List<Map<String, dynamic>> result = await db.rawQuery(query);
    return result;
  }

  Future<List<Map<String, dynamic>>> getFavoriteCategories() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    const String query = """
    SELECT DISTINCT categories.id, categories.name
    FROM user_favorites
    JOIN category_content ON user_favorites.content_id = category_content.id
    JOIN categories ON category_content.category_id = categories.id
    WHERE user_favorites.favorite_status = 1
  """;
    final List<Map<String, dynamic>> result = await db.rawQuery(query);
    return result;
  }

  Future<List<Map<String, dynamic>>> getFavoriteCultures() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    const String query = """
  SELECT DISTINCT cultures.id, cultures.name
  FROM user_favorites
  JOIN culture_content ON user_favorites.content_id = culture_content.id
  JOIN cultures ON culture_content.culture_id = cultures.id
  WHERE user_favorites.favorite_status = 1
""";
    final List<Map<String, dynamic>> result = await db.rawQuery(query);
    return result;
  }




// Add this method to update the favorite status of a content
  Future<void> updateDeviceFavoriteStatus(String contentId, bool isFavorite) async {
    if (isFavorite) {
      await addToDeviceFavorites(contentId);
    } else {
      await removeFromDeviceFavorites(contentId);
    }
  }

// Query content by search query
  Future<Map<String, dynamic>?> getRandomQuote() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
SELECT * FROM (
  SELECT author_content.id, content, name as author, authors.image_remote as author_image_remote, authors.image_local as author_image_local, author_content.timestamp FROM author_content
  INNER JOIN authors ON author_quotes.author_id = authors.id
  UNION ALL
  SELECT category_content.id, content, name as author, categories.icon_remote as author_image_remote, categories.icon_local as author_image_local, category_content.timestamp FROM category_content
  INNER JOIN categories ON category_content.category_id = categories.id
) AS combined_content
ORDER BY RANDOM()
LIMIT 1
  ''');
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }


  // Query all favorite content
  Future<List<Map<String, dynamic>>> queryAllFavoriteContent() async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final db = await database;
    return await db.rawQuery('''
SELECT * FROM (
  SELECT * FROM $tableAuthorContent
  UNION ALL
  SELECT * FROM $tableCategoryContent
) AS combined_content
WHERE id IN (
  SELECT content_id FROM $tableDeviceFavoriteContent
  WHERE user_id = ? AND favorite_status = 1
)
ORDER BY last_updated DESC
''', [userId]);
  }


  // Update content
  Future<int> updateContent(int contentId, String contentText, int? categoryId, int? authorId) async {
    final db = await database;

    int updatedRows = 0;

    if (authorId != null) {
      updatedRows = await db.update(
        tableAuthorContent,
        {
          'content': contentText,
          'author_id': authorId,
        },
        where: 'id = ?',
        whereArgs: [contentId],
      );
    }

    if (categoryId != null && updatedRows == 0) {
      updatedRows = await db.update(
        tableCategoryContent,
        {
          'content': contentText,
          'category_id': categoryId,
        },
        where: 'id = ?',
        whereArgs: [contentId],
      );
    }

    return updatedRows;
  }


// Delete content
  Future<int> deleteContent(int contentId) async {
    final db = await database;

    int deletedRows;
    deletedRows = await db.delete(
      tableAuthorContent,
      where: 'id = ?',
      whereArgs: [contentId],
    );

    if (deletedRows == 0) {
      deletedRows = await db.delete(
        tableCategoryContent,
        where: 'id = ?',
        whereArgs: [contentId],
      );
    }

    return deletedRows;
  }

  Future<Map<String, dynamic>?> fetchAndSaveContent(String qid, bool isAuthorContent, bool isCultureContent, bool isCategoryContent) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String tableName;
    if (isAuthorContent) {
      tableName = tableAuthorContent;
    } else if (isCultureContent) {
      tableName = tableCultureContent;
    } else if (isCategoryContent) {
      tableName = tableCategoryContent;
    } else {
      return null; // Invalid content type
    }

    DocumentSnapshot contentSnapshot = await firestore.collection(tableName).doc(qid).get();
    if (!contentSnapshot.exists) {
      return null; // Content not found in Firestore
    }

    Map<String, dynamic> contentData = contentSnapshot.data() as Map<String, dynamic>;
    contentData['id'] = contentSnapshot.id;

    if (contentData['image_remote'] != null) {
      final imagePath = await _downloadImageWithRetry(contentData['image_remote']);
      if (imagePath != null) {
        contentData['image_local'] = imagePath;
      }
    }

    await db.transaction((txn) async {
      await txn.insert(
        tableName,
        convertTimestamps(contentData),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

// Remove author_id, category_id, or culture_id from the respective 'synced' set
    if (isAuthorContent) {
      Set<String> syncedAuthorIds = prefs.getStringList('synced_author_ids')?.toSet() ?? {};
      syncedAuthorIds.remove(contentData['author_id']);
      await prefs.setStringList('synced_author_ids', syncedAuthorIds.toList());
    } else if (isCategoryContent) {
      Set<String> syncedCategoryIds = prefs.getStringList('synced_category_ids')?.toSet() ?? {};
      syncedCategoryIds.remove(contentData['category_id']);
      await prefs.setStringList('synced_category_ids', syncedCategoryIds.toList());
    } else if (isCultureContent) {
      Set<String> syncedCultureIds = prefs.getStringList('synced_culture_ids')?.toSet() ?? {};
      syncedCultureIds.remove(contentData['culture_id']);
      await prefs.setStringList('synced_culture_ids', syncedCultureIds.toList());
    }

    return contentData;
  }



  Future<Map<String, dynamic>?> fetchAndSaveAuthor(String authorId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;

    DocumentSnapshot authorSnapshot = await firestore.collection(tableAuthors).doc(authorId).get();
    if (!authorSnapshot.exists) {
      return null; // Author not found in Firestore
    }

    Map<String, dynamic> authorData = authorSnapshot.data() as Map<String, dynamic>;
    authorData['id'] = authorSnapshot.id;

    // Download author image
    if (authorData['image_remote'] != null) {
      final imagePath = await _downloadImageWithRetry(authorData['image_remote']);
      if (imagePath != null) {
        authorData['image_local'] = imagePath;
      }
    }

    await db.transaction((txn) async {
      await txn.insert(
        tableAuthors,
        convertTimestamps(authorData),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return authorData;
  }

  Future<Map<String, dynamic>?> fetchAndSaveCategory(String categoryId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;

    DocumentSnapshot categorySnapshot = await firestore.collection(tableCategories).doc(categoryId).get();
    if (!categorySnapshot.exists) {
      return null; // Category not found in Firestore
    }

    Map<String, dynamic> categoryData = categorySnapshot.data() as Map<String, dynamic>;
    categoryData['id'] = categorySnapshot.id;

    // Download category image
    if (categoryData['icon_remote'] != null) {
      final imagePath = await _downloadImageWithRetry(categoryData['icon_remote']);
      if (imagePath != null) {
        categoryData['icon_local'] = imagePath;
      }
    }

    await db.transaction((txn) async {
      await txn.insert(
        tableCategories,
        convertTimestamps(categoryData),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return categoryData;
  }

  Future<Map<String, dynamic>?> fetchAndSaveCulture(String cultureId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final db = await database;

    DocumentSnapshot cultureSnapshot = await firestore.collection(tableCultures).doc(cultureId).get();
    if (!cultureSnapshot.exists) {
      return null; // Culture not found in Firestore
    }

    Map<String, dynamic> cultureData = cultureSnapshot.data() as Map<String, dynamic>;
    cultureData['id'] = cultureSnapshot.id;

    // Download culture image
    if (cultureData['image_remote'] != null) {
      final imagePath = await _downloadImageWithRetry(cultureData['image_remote']);
      if (imagePath != null) {
        cultureData['image_local'] = imagePath;
      }
    }

    await db.transaction((txn) async {
      await txn.insert(
        tableCultures,
        convertTimestamps(cultureData),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return cultureData;
  }


// Query content by category id
  Future<List<Map<String, dynamic>>> queryContentByCategoryId(int categoryId) async {
    final db = await database;
    return await db.query(
      tableCategoryContent,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> queryContentByAuthor(String authorId) async {
    final db = await database;
    return await db.query(
      tableAuthorContent,
      where: 'author_id = ?',
      whereArgs: [authorId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<Map<String, dynamic>?> getAuthorById(String authorId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableAuthors,
      where: 'id = ?',
      whereArgs: [authorId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableCategories, // this should be your categories table name
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCultureById(String cultureId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableCultures, // this should be your categories table name
      where: 'id = ?',
      whereArgs: [cultureId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

// Query content by author id
  Future<List<Map<String, dynamic>>> queryContentByAuthorId(int authorId) async {
    final db = await database;
    return await db.query(
      tableAuthorContent,
      where: 'author_id = ?',
      whereArgs: [authorId],
      orderBy: 'timestamp DESC',
    );
  }


  Future<void> updateFirestoreDeviceFavoriteContent(String contentId, bool isFavorite) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final docRef = firestore
        .collection(tableDeviceFavoriteContent)
        .doc('$userId-$contentId');

    if (isFavorite) {
      await docRef.set({
        'content_id': contentId,
        'user_id': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }


  Future<String> fetchAuthorImageLocal(int authorId) async {
    final db = await database;
    final result = await db.query(
      'authors',
      columns: ['image_local'],
      where: 'id = ?',
      whereArgs: [authorId],
    );

    if (result.isNotEmpty) {
      return result.first['image_local'] as String? ?? '';
    } else {
      return '';
    }
  }

  // Get all background images from the background_images table
  Future<List<Map<String, dynamic>>> queryAllBackgroundImages() async {
    Database db = await instance.database;
    return await db.query('background_images');
  }

  // Add this method in your DatabaseHelper class
  Future<void> submitContactForm(String name, String email, String message) async {
    final userId = await DeviceManager(firestore: FirebaseFirestore.instance).getUserId();
    final contactMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await FirebaseFirestore.instance
          .collection('contact_messages')
          .doc(contactMessageId)
          .set({
        'id': contactMessageId,
        'user_id': userId,
        'name': name,
        'email': email,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
     // print('Error submitting contact form: $e');
      // Handle the error appropriately
    }
  }

  Future<Map<String, dynamic>> fetchAdUnit(String unitId) async {
    try {
      final DocumentReference unitRef = FirebaseFirestore.instance
          .collection('ads')
          .doc('adSettings')
          .collection('units')
          .doc(unitId);
      final DocumentSnapshot unitSnapshot = await unitRef.get();

      Map<String, dynamic> adUnit = {
        'adProvider': unitSnapshot['adProvider'] ?? 'admob',
        'enabled': unitSnapshot['enabled'] ?? false,
        'adUnitId': unitSnapshot['adUnitId'] ?? '',
        'customAdCode': unitSnapshot['customAdCode'] ?? '',
        'adFormat': unitSnapshot['adFormat'] ?? 'banner',
        'position': unitSnapshot['position'] ?? '',
      };

      return adUnit;
    } catch (e) {
     // print("Error fetching ad unit: $e");
      return {
        'adProvider': 'admob',
        'enabled': false,
        'adUnitId': '',
        'customAdCode': '',
        'adFormat': 'banner',
        'position': '',
      }; // Return default values in case of an error
    }
  }


  Future<Map<String, dynamic>> fetchAdSettings() async {
    try {
      final CollectionReference unitsRef = FirebaseFirestore.instance.collection('ads').doc('adSettings').collection('units');
      final unitsSnapshot = await unitsRef.get();

      Map<String, dynamic> adSettings = {};

      for (final doc in unitsSnapshot.docs) {
        String unitId = doc.id;
        adSettings[unitId] = {
          'adProvider': doc['adProvider'] ?? 'admob',
          'enabled': doc['enabled'] ?? false,
          'adUnitId': doc['adUnitId'] ?? '',
          'customAdCode': doc['customAdCode'] ?? '',
          'adFormat': doc['adFormat'] ?? 'banner',
          'position': doc['position'] ?? '',
        };
      }

      return adSettings;
    } catch (e) {
     // print("Error fetching ad settings: $e");
      return {
        'ad_unit_1': {
          'adProvider': 'admob',
          'enabled': false,
          'adUnitId': '',
          'customAdCode': '',
          'adFormat': 'banner',
          'position': '',
        },
        'ad_unit_2': {
          'adProvider': 'admob',
          'enabled': false,
          'adUnitId': '',
          'customAdCode': '',
          'adFormat': 'banner',
          'position': '',
        },
        // ... more default values for other ad units if needed
      }; // Return default values in case of an error
    }
  }


  Future<Map<String, dynamic>?> getContentById(String contentId, String type) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (type == 'author') {
      result = await db.query(tableAuthorContent, where: 'id = ?', whereArgs: [contentId]);
    } else if (type == 'category') {
      result = await db.query(tableCategoryContent, where: 'id = ?', whereArgs: [contentId]);
    } else if (type == 'culture') {
      result = await db.query(tableCultureContent, where: 'id = ?', whereArgs: [contentId]);
    } else {
      throw ArgumentError('Invalid content type: $type');
    }

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }


  Future<void> syncQuoteFromFirestoreToSQLite(Map<String, dynamic> contentData, String type) async {
    final db = await database;
    String tableName;

    if (type == 'author') {
      tableName = tableAuthorContent;
    } else if (type == 'category') {
      tableName = tableCategoryContent;
    } else if (type == 'culture') {
      tableName = tableCultureContent;
    } else {
      throw ArgumentError('Invalid content type: $type');
    }

    await db.insert(tableName, contentData, conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<void> syncAuthorOrCategoryorCultureFromFirestoreToSQLite(Map<String, dynamic> authorOrCategoryorCultureData, String type) async {
    final db = await database;
    String tableName;

    if (type == 'author') {
      tableName = tableAuthors;
    } else if (type == 'category') {
      tableName = tableCategories;
    } else if (type == 'culture') {
      tableName = tableCultures;
    } else {
      throw ArgumentError('Invalid type: $type');
    }

    await db.insert(tableName, authorOrCategoryorCultureData, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

Future<String> downloadAndSaveImage(String imageUrl, String filename) async {
 // print('Downloading image from $imageUrl...');
  final response = await http.get(Uri.parse(imageUrl));

  if (response.statusCode == 200) {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String imagePath = '${appDocDir.path}/$filename';
    File file = File(imagePath);
    await file.writeAsBytes(response.bodyBytes);

    return imagePath;
  } else {
    throw Exception('Failed to download image from $imageUrl');
  }
}
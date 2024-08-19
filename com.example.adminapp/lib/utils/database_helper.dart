import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 1;

  static const categoryTable = 'categories';
  static const authorTable = 'authors';
  static const cultureTable = 'cultures';
  static const backgroundimagesTable = 'background_images';
  static const authorContentTable = 'author_content';
  static const categoryContentTable = 'category_content';
  static const cultureContentTable = 'culture_content';

  // Common columns
  static const columnId = 'id';
  static const columnName = 'name';
  static const columnTimestamp = 'timestamp';

  // Author-specific columns
  static const columnAuthorImageRemote = 'image_remote';
  static const columnAuthorImageLocal = 'image_local';

  static const columnCultureImageRemote = 'image_remote';
  static const columnCultureImageLocal = 'image_local';

  // Category-specific columns
  static const columnCategoryIconRemote = 'icon_remote';
  static const columnCategoryIconLocal = 'icon_local';

  // Quote-specific columns
  static const columnContent = 'quote';
  static const columnAuthorId = 'author_id';
  static const columnCategoryId = 'category_id';
  static const columnCultureId = 'culture_id';

  // Singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database reference
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database tables
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $categoryTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnName TEXT NOT NULL,
            $columnCategoryIconLocal TEXT NOT NULL,
            $columnCategoryIconRemote TEXT NOT NULL,
            $columnTimestamp TEXT NOT NULL
          )
          ''');

    await db.execute('''
          CREATE TABLE IF NOT EXISTS $authorTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnName TEXT NOT NULL,
            $columnAuthorImageLocal TEXT NOT NULL,
            $columnAuthorImageRemote TEXT NOT NULL,
            $columnTimestamp TEXT NOT NULL
          )
          ''');

    await db.execute('''
          CREATE TABLE IF NOT EXISTS $authorContentTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnContent TEXT NOT NULL,
            $columnAuthorId INTEGER NOT NULL,
            $columnTimestamp TEXT NOT NULL,
            FOREIGN KEY ($columnAuthorId) REFERENCES $authorTable ($columnId)
          )
          ''');

    await db.execute('''
          CREATE TABLE IF NOT EXISTS $categoryContentTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnContent TEXT NOT NULL,
            $columnCategoryId INTEGER NOT NULL,
            $columnTimestamp TEXT NOT NULL,
            FOREIGN KEY ($columnCategoryId) REFERENCES $categoryTable ($columnId)
          )
          ''');
  }

  // Helper methods
  Future<int> addCategory(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(categoryTable, row);
  }

  Future<int> addAuthor(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(authorTable, row);
  }

  Future<int> addCulture(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(cultureTable, row);
  }

  Future<int> addBackgroundImg(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(backgroundimagesTable, row);
  }

  Future<int> addAuthorContent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(authorContentTable, row);
  }

  Future<int> addCategoryContent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(categoryContentTable, row);
  }

  Future<int> addCultureContent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(cultureContentTable, row);
  }

  static Future<void> updateCategory(Map<String, dynamic> categoryData) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the category data in the database.
    await db.update(
      'categories',
      categoryData,
      where: 'id = ?',
      whereArgs: [categoryData['id']],
    );
  }

  static Future<void> updateAuthor(Map<String, dynamic> authorData) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the author data in the database.
    await db.update(
      'authors',
      authorData,
      where: 'id = ?',
      whereArgs: [authorData['id']],
    );
  }

  static Future<void> updateCulture(Map<String, dynamic> cultureData) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the category data in the database.
    await db.update(
      'cultures',
      cultureData,
      where: 'id = ?',
      whereArgs: [cultureData['id']],
    );
  }

  static Future<void> updateBackgroundImg(Map<String, dynamic> backgroundData) async {
    // Get a reference to the database.
    final db = await instance.database;

    // Update the category data in the database.
    await db.update(
      'background_images',
      backgroundData,
      where: 'id = ?',
      whereArgs: [backgroundData['id']],
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;

    // Delete the category from the local SQLite database
    await db.delete(
      categoryTable,
      where: '$columnId = ?', // Use 'id' as the field in the WHERE clause
      whereArgs: [int.parse(categoryId)],
    );
  }

  Future<void> deleteCulture(String cultureId) async {
    final db = await database;

    // Delete the category from the local SQLite database
    await db.delete(
      cultureTable,
      where: '$columnId = ?',
      whereArgs: [int.parse(cultureId)],
    );
  }

  Future<void> deleteAuthor(String authorId) async {
    final db = await database;

    // Delete the category from the local SQLite database
    await db.delete(
      authorTable,
      where: '$columnId = ?',
      whereArgs: [int.parse(authorId)],
    );
  }

// Add more methods to interact with the database as needed
}

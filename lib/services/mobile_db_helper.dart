import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MobileDBHelper {
  static Database? _database;
  static const String _dbName = 'cs_exit_exam.db';
  static const int _dbVersion = 3; // Updated to 3 for topic/difficulty columns

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Platform-specific initialization for Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get the correct database path based on platform
    Directory documentsDirectory;
    if (Platform.isAndroid || Platform.isIOS) {
      documentsDirectory = await getApplicationDocumentsDirectory();
    } else {
      documentsDirectory = await getApplicationSupportDirectory();
    }
    
    final dbPath = p.join(documentsDirectory.path, _dbName);
    debugPrint('📁 Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        score REAL NOT NULL,
        correct_count INTEGER NOT NULL,
        incorrect_count INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        time_spent INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        topic TEXT DEFAULT 'General',
        difficulty TEXT DEFAULT 'Mixed'
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL UNIQUE,
        last_score REAL,
        best_score REAL,
        total_attempts INTEGER DEFAULT 0,
        total_correct INTEGER DEFAULT 0,
        total_questions INTEGER DEFAULT 0,
        last_attempt TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Upgrade from v1 to v2: Add user_progress table
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_id INTEGER NOT NULL UNIQUE,
          last_score REAL,
          best_score REAL,
          total_attempts INTEGER DEFAULT 0,
          total_correct INTEGER DEFAULT 0,
          total_questions INTEGER DEFAULT 0,
          last_attempt TEXT,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }

    // Upgrade from v2 to v3: Add new metadata columns to results
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE results ADD COLUMN topic TEXT DEFAULT 'General'");
        await db.execute("ALTER TABLE results ADD COLUMN difficulty TEXT DEFAULT 'Mixed'");
      } catch (e) {
        debugPrint('⚠️ Migration error or columns already exist: $e');
      }
    }
  }

  // --- CRUD Operations ---

  static Future<int> insertResult(Map<String, dynamic> result) async {
    try {
      final db = await database;
      return await db.insert('results', result);
    } catch (e) {
      debugPrint('❌ Error inserting result: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllResults() async {
    try {
      final db = await database;
      return await db.query('results', orderBy: 'completed_at DESC');
    } catch (e) {
      debugPrint('❌ Error getting results: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getResultsBySubject(int subjectId) async {
    try {
      final db = await database;
      return await db.query(
        'results',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
        orderBy: 'completed_at DESC',
      );
    } catch (e) {
      debugPrint('❌ Error getting results by subject: $e');
      return [];
    }
  }

  static Future<int> deleteResult(int id) async {
    try {
      final db = await database;
      return await db.delete('results', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('❌ Error deleting result: $e');
      return 0;
    }
  }

  static Future<void> clearAllResults() async {
    try {
      final db = await database;
      await db.delete('results');
      await db.delete('user_progress');
    } catch (e) {
      debugPrint('❌ Error clearing results: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserProgress(int subjectId) async {
    try {
      final db = await database;
      final results = await db.query(
        'user_progress',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('❌ Error getting user progress: $e');
      return null;
    }
  }

  static Future<void> updateUserProgress(Map<String, dynamic> progress) async {
    try {
      final db = await database;
      final subjectId = progress['subject_id'] as int;
      
      final existing = await db.query(
        'user_progress',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      
      if (existing.isEmpty) {
        await db.insert('user_progress', progress);
      } else {
        await db.update(
          'user_progress',
          progress,
          where: 'subject_id = ?',
          whereArgs: [subjectId],
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating user progress: $e');
    }
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
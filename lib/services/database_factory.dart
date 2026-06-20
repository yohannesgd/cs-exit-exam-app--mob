// services/database_factory.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabaseFactory {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize FFI for Windows/Linux/Mac
    sqfliteFfiInit();
    
    // Set the database factory to FFI for desktop platforms
    sql.databaseFactory = databaseFactoryFfi;
    
    _initialized = true;
    debugPrint('✅ Database factory initialized for desktop platform');
  }

  static Future<sql.Database> openDatabase({
    required String path,
    int? version,
    sql.OnDatabaseConfigureFn? onConfigure,
    sql.OnDatabaseCreateFn? onCreate,
    sql.OnDatabaseVersionChangeFn? onUpgrade,
    sql.OnDatabaseVersionChangeFn? onDowngrade,
    sql.OnDatabaseOpenFn? onOpen,
    bool readOnly = false,
  }) async {
    await initialize();
    
    return await sql.databaseFactory.openDatabase(
      path,
      options: sql.OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
        readOnly: readOnly,
      ),
    );
  }
}
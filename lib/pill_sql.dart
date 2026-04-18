import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Database schema definitions
  final String tablePills = 'pills';
  final String columnId = 'id';
  final String columnName = 'name';
  final String columnDescription = 'description';
  final String columnAmount = 'amount';
  final String columnScheduledTime = 'scheduled_time';
  final String columnCreatedAt = 'created_at';
  final String columnImagePath = 'image_path';
  final String columnMealType = 'meal_type';
  final String columnTimingType = 'timing_type';
  final String columnDose = 'dose'; 

  final String tableHistory = 'pill_history';
  final String columnHistoryId = 'id';
  final String columnPillId = 'pill_id';
  final String columnPillName = 'pill_name';
  final String columnTakenDate = 'taken_date';
  final String columnTakenTime = 'taken_time';
  final String columnStatus = 'status';

  // Gets the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medification_v_dose.db');
    return _database!;
  }

  // Initializes the SQLite database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Creates database tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePills (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnDescription TEXT,
        $columnAmount REAL NOT NULL, 
        $columnScheduledTime TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL,
        $columnImagePath TEXT,
        $columnMealType TEXT,
        $columnTimingType TEXT,
        $columnDose TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableHistory (
        $columnHistoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnPillId INTEGER,
        $columnPillName TEXT,
        $columnTakenDate TEXT,
        $columnTakenTime TEXT,
        $columnStatus TEXT
      )
    ''');
  }

  // Inserts a new pill record
  Future<int> insertPill(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tablePills, row);
  }

  // Retrieves all stored pills
  Future<List<Map<String, dynamic>>> readAllPills() async {
    Database db = await instance.database;
    return await db.query(tablePills, orderBy: '$columnScheduledTime ASC');
  }

  // Updates a pill's scheduled time
  Future<int> updatePillTime(int id, String newTime) async {
    Database db = await instance.database;
    return await db.update(
      tablePills,
      {columnScheduledTime: newTime},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Updates a pill's complete information
  Future<int> updatePill(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(
      tablePills,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Updates the remaining amount of a pill
  Future<int> updatePillAmount(int id, num amount) async {
    Database db = await instance.database;
    return await db.update(
      tablePills,
      {columnAmount: amount},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes a pill record
  Future<int> deletePill(int id) async {
    Database db = await instance.database;
    return await db.delete(tablePills, where: '$columnId = ?', whereArgs: [id]);
  }

  // Inserts a history log for pill intake
  Future<int> insertHistoryLog(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableHistory, row);
  }

  // Retrieves all pill intake history
  Future<List<Map<String, dynamic>>> readAllHistory() async {
    Database db = await instance.database;
    return await db.query(
      tableHistory,
      orderBy: '$columnTakenDate DESC, $columnTakenTime DESC',
    );
  }

  // Checks if a specific pill was taken today
  Future<bool> hasTakenPillToday(int pillId, String date) async {
    Database db = await instance.database;
    final res = await db.query(
      tableHistory,
      where: '$columnPillId = ? AND $columnTakenDate = ? AND $columnStatus = ?',
      whereArgs: [pillId, date, 'Taken'],
    );
    return res.isNotEmpty;
  }

  // Checks if a specific pill was missed today
  Future<bool> hasMissedPillToday(int pillId, String date) async {
    Database db = await instance.database;
    final res = await db.query(
      tableHistory,
      where: '$columnPillId = ? AND $columnTakenDate = ? AND $columnStatus = ?',
      whereArgs: [pillId, date, 'Missed'],
    );
    return res.isNotEmpty;
  }
}
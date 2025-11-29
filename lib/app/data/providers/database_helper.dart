import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/medication_model.dart';
import '../models/dose_log_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medify.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Medications Table
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        dosage REAL NOT NULL,
        unit TEXT NOT NULL,
        color_tag TEXT,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        instructions TEXT,
        quantity INTEGER,
        refill_threshold INTEGER,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Dose Logs Table
    await db.execute('''
      CREATE TABLE dose_logs (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        scheduled_time INTEGER NOT NULL,
        actual_time INTEGER,
        status TEXT NOT NULL,
        reason TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
  }

  // --- Medication Operations ---

  Future<int> insertMedication(MedicationModel medication) async {
    final db = await database;
    return await db.insert(
      'medications',
      medication.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MedicationModel?> getMedication(String id) async {
    final db = await database;
    final maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return MedicationModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<MedicationModel>> getAllMedications(String userId) async {
    final db = await database;
    final maps = await db.query(
      'medications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return MedicationModel.fromMap(maps[i]);
    });
  }

  Future<int> updateMedication(MedicationModel medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Dose Log Operations ---

  Future<int> insertDoseLog(DoseLogModel log) async {
    final db = await database;
    return await db.insert(
      'dose_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DoseLogModel>> getDoseLogsForMedication(String medicationId) async {
    final db = await database;
    final maps = await db.query(
      'dose_logs',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'scheduled_time DESC',
    );

    return List.generate(maps.length, (i) {
      return DoseLogModel.fromMap(maps[i]);
    });
  }

  Future<List<DoseLogModel>> getDoseLogsForDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'dose_logs',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'scheduled_time ASC',
    );

    return List.generate(maps.length, (i) {
      return DoseLogModel.fromMap(maps[i]);
    });
  }
  
  Future<int> updateDoseLog(DoseLogModel log) async {
    final db = await database;
    return await db.update(
      'dose_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // --- Sync Queue Operations ---

  Future<int> addToSyncQueue(String operation, String tableName, String recordId, String data) async {
    final db = await database;
    return await db.insert(
      'sync_queue',
      {
        'operation': operation,
        'table_name': tableName,
        'record_id': recordId,
        'data': data,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<int> removeFromSyncQueue(int id) async {
    final db = await database;
    return await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('medications');
    await db.delete('dose_logs');
    await db.delete('sync_queue');
  }
}

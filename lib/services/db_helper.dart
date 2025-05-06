import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../model/user.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  Future<Database?> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');
    return openDatabase(
      path,
      version: 3, // bumped from 1 → 2
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user (
            id             INTEGER PRIMARY KEY,
            name           TEXT,
            email          TEXT,
            phone          TEXT,
            password       TEXT,
            role           INTEGER,
            image        TEXT,
            imageType    TEXT,
            connected      INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
        CREATE TABLE process (
          id INTEGER PRIMARY KEY,
          name TEXT,
          workflow_id INTEGER,
          status_id INTEGER,
          created_by INTEGER,
          is_synced INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE subprocess (
          id INTEGER PRIMARY KEY,
          name TEXT,
          process_id INTEGER,
          status INTEGER,
          assigned_to INTEGER,
          is_synced INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE notification (
          id INTEGER PRIMARY KEY,
          user_to_notify INTEGER,
          message TEXT,
          visiblity INTEGER,
          is_synced INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE role (
          id INTEGER PRIMARY KEY,
          name TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE status (
          id INTEGER PRIMARY KEY,
          name TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE workflow (
          id INTEGER PRIMARY KEY,
          name TEXT,
          created_by INTEGER,
          is_synced INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0,
          needs_update INTEGER DEFAULT 0
        )
      ''');

        print('on create worked');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE user ADD COLUMN profilePicture TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE user ADD COLUMN image TEXT');
          await db.execute('ALTER TABLE user ADD COLUMN imageType TEXT');
        }
      },
    );
  }

  Future<void> saveUser(User user) async {
    final db = await database;
    await db!.update('user', {'connected': 0}); // logout all
    await db!.insert('user', {...user.toJson(), 'connected': 1},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser() async {
    final db = await database;
    final rows = await db!
        .query('user', where: 'connected = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    return User.fromJson(rows.first);
  }

  Future<void> deleteUser() async {
    final db = await database;
    await db!.update('user', {'connected': 0},
        where: 'connected = ?', whereArgs: [1]);
  }

  readData(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db!.rawQuery(sql, args);
  }

  insertData(String sql,[List<dynamic>? args]) async {
    Database? mydb = await database;
    int response = await mydb!.rawInsert(sql,args);
    return response;
  }

  updateData(String sql) async {
    Database? mydb = await database;
    int response = await mydb!.rawUpdate(sql);
    return response;
  }

  deleteData(String sql) async {
    Database? mydb = await database;
    int response = await mydb!.rawDelete(sql);
    return response;
  }
}

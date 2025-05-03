import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../model/user.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, ver) async {
        await db.execute('''
          CREATE TABLE user (
            id      INTEGER PRIMARY KEY,
            name    TEXT,
            email   TEXT,
            phone   TEXT,
            password TEXT,
            role    INTEGER,
          )
        ''');
      },
    );
  }

  Future<void> saveUser(User user) async {
    final db = await database;
    // only one row, so clear first:
    await db.delete('user');
    await db.insert('user', user.toJson());
  }

  Future<User?> getUser() async {
    final db = await database;
    final rows = await db.query('user', limit: 1);
    if (rows.isEmpty) return null;
    return User.fromJson(rows.first);
  }

  Future<void> deleteUser() async {
    final db = await database;
    await db.delete('user');
  }
}

class CustomDatabase {
}

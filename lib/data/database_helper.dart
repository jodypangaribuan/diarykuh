import 'package:diarykuh/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static final _databaseVersion = 4; // Increment version number

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'diary_database.db');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT,
        content TEXT,
        mood TEXT,
        timestamp TEXT,
        voicePath TEXT,
        imagePath TEXT,
        imagePaths TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        uid TEXT PRIMARY KEY,
        name TEXT,
        email TEXT UNIQUE,
        phone TEXT,
        password TEXT,
        imagePath TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN imagePaths TEXT');
    }
    if (oldVersion < 3) {
      // Add user_id column and set default value
      await db.execute('ALTER TABLE notes ADD COLUMN user_id TEXT');
      await db.execute('UPDATE notes SET user_id = "default_user"');
    }
    if (oldVersion < 4) {
      // Add password column to users table
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
    }
  }

  Future<int> insertNote(Note note) async {
    if (note.userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<int> updateNote(Note note) async {
    if (note.userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [note.id, note.userId],
    );
  }

  Future<int> deleteNote(int id, String userId) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(String uid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'diary_database.db');
  }

  Future<void> copyDatabaseToExternalStorage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    String dbPath = await getDatabasePath();
    String externalStoragePath = '/storage/emulated/0/Disini/diary_database.db';
    File(dbPath).copy(externalStoragePath);
    print('Database copied to: $externalStoragePath');
  }

  List<String> getImagePaths(String content) {
    if (content.isEmpty) return [];
    return content.split('|');
  }
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DatabaseHelper dbHelper = DatabaseHelper();
//   String dbPath = await dbHelper.getDatabasePath();
//   print('Database path: $dbPath');
//   await dbHelper.copyDatabaseToExternalStorage();
// }

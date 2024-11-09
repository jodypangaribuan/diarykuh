import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static final _databaseVersion = 2;

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
        title TEXT,
        content TEXT,
        mood TEXT,
        timestamp TEXT,
        voicePath TEXT,
        imagePath TEXT,
        imagePaths TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN imagePaths TEXT');
    }
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('notes', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
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
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DatabaseHelper dbHelper = DatabaseHelper();
//   String dbPath = await dbHelper.getDatabasePath();
//   print('Database path: $dbPath');
//   await dbHelper.copyDatabaseToExternalStorage();
// }

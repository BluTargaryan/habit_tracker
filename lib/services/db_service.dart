import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/user.dart';

class DbService {
  DbService._internal();
  static final DbService instance = DbService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'habit_tracker.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createHabitTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createHabitTables(db);
        }
      },
    );
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        age INTEGER NOT NULL,
        country TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createHabitTables(Database db) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        isOutdoor INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE habit_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        UNIQUE(habitId, date),
        FOREIGN KEY(habitId) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final habitRows = await db.query('habits', orderBy: 'createdAt ASC');
    final habits = <Habit>[];
    for (final row in habitRows) {
      final completionRows = await db.query(
        'habit_completions',
        where: 'habitId = ?',
        whereArgs: [row['id']],
      );
      habits.add(
        Habit.fromMap(
          row,
          completions: completionRows.map(HabitCompletion.fromMap).toList(),
        ),
      );
    }
    return habits;
  }

  Future<void> setCompletionForToday(String habitId, bool completed) async {
    final db = await database;
    final completion = HabitCompletion(date: DateTime.now(), completed: completed);
    await db.insert(
      'habit_completions',
      completion.toMap(habitId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }
}

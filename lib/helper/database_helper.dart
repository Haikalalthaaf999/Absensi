import 'package:project3/models/user_model.dart';
import 'package:project3/models/attendance_model.dart';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDb();

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'absensi_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password TEXT NOT NULL, role TEXT NOT NULL)
    ''');
    await db.execute('''
      CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER NOT NULL, jamMasuk TEXT, jamPulang TEXT, lokasiMasuk TEXT, lokasiPulang TEXT, FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE)
    ''');
  }

  String _hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();

  Future<void> registerUser(String nama, String email, String password) async {
    final db = await database;
    var userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    await db.insert('users', {'nama': nama, 'email': email, 'password': _hashPassword(password), 'role': (userCount == 0) ? 'admin' : 'user'});
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    var res = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, _hashPassword(password)]);
    return res.isNotEmpty ? User.fromMap(res.first) : null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    var res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? User.fromMap(res.first) : null;
  }

  Future<void> clockIn(int userId, String lokasi) async {
    final db = await database;
    await db.insert('attendance', {'userId': userId, 'jamMasuk': DateTime.now().toIso8601String(), 'lokasiMasuk': lokasi});
  }

  Future<void> clockOut(int attendanceId, String lokasi) async {
    final db = await database;
    await db.update('attendance', {'jamPulang': DateTime.now().toIso8601String(), 'lokasiPulang': lokasi}, where: 'id = ?', whereArgs: [attendanceId]);
  }

  Future<Attendance?> getOpenAttendance(int userId) async {
    final db = await database;
    final res = await db.query('attendance', where: 'userId = ? AND jamPulang IS NULL', whereArgs: [userId], orderBy: 'id DESC', limit: 1);
    return res.isNotEmpty ? Attendance.fromMap(res.first) : null;
  }

  Future<List<Attendance>> getAttendanceHistory(int userId) async {
    final db = await database;
    final maps = await db.query('attendance', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getAdminAttendanceHistory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT A.jamMasuk, A.jamPulang, U.nama FROM attendance A INNER JOIN users U ON A.userId = U.id ORDER BY A.id DESC
    ''');
  }
}
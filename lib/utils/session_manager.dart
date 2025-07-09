// lib/utils/session_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Pastikan path ini benar
import '../models/batch_model.dart';
import '../models/training_model.dart';
import '../models/attendance_model.dart'; // BARU: Import model Attendance

class SessionManager {
  // Method untuk menyimpan sesi awal saat login
  Future<void> saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    // Panggil saveUser untuk menyimpan detail user
    await saveUser(user);
  }

  // Method untuk menyimpan atau memperbarui data User secara spesifik
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);

    if (user.gender != null) {
      await prefs.setString('user_gender', user.gender!);
    }
    if (user.profilePhotoUrl != null) {
      await prefs.setString('user_photo', user.profilePhotoUrl!);
    }
    // Simpan data kompleks (training & batch) sebagai string JSON
    if (user.training != null) {
      await prefs.setString(
        'user_training',
        jsonEncode(user.training!.toJson()),
      );
    }
    if (user.batch != null) {
      await prefs.setString('user_batch', jsonEncode(user.batch!.toJson()));
    }
  }

  // Method untuk mengambil token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Method untuk mengambil data user lengkap yang tersimpan di sesi
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      return null; // Tidak ada sesi aktif
    }

    // Ambil data training dan batch dari JSON String
    final trainingString = prefs.getString('user_training');
    final batchString = prefs.getString('user_batch');

    return User(
      id: prefs.getInt('user_id') ?? 0,
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      gender: prefs.getString('user_gender'),
      profilePhotoUrl: prefs.getString('user_photo'),
      // Decode JSON string kembali menjadi object, jika ada
      training: trainingString != null
          ? Datum.fromJson(jsonDecode(trainingString))
          : null,
      batch: batchString != null
          ? BatchData.fromJson(jsonDecode(batchString))
          : null,
    );
  }

  // --- TAMBAHKAN SEMUA FUNGSI BARU DI BAWAH INI ---

  // Fungsi untuk menyimpan data absensi hari ini ke SharedPreferences
  Future<void> saveTodayAttendance(Map<String, dynamic> attendanceData) async {
    final prefs = await SharedPreferences.getInstance();
    String attendanceJson = json.encode(attendanceData);
    await prefs.setString('today_attendance', attendanceJson);
    // Simpan juga tanggalnya untuk perbandingan nanti
    String todayDate = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('attendance_date', todayDate);
  }

  // Fungsi untuk mengambil data absensi hari ini dari SharedPreferences
  Future<Attendance?> getTodayAttendanceFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? attendanceJson = prefs.getString('today_attendance');
    String? savedDate = prefs.getString('attendance_date');
    String todayDate = DateTime.now().toIso8601String().substring(0, 10);

    // Hanya kembalikan data jika data ada DAN tanggalnya sama dengan hari ini
    if (attendanceJson != null && savedDate == todayDate) {
      return Attendance.fromJson(json.decode(attendanceJson));
    }

    // Jika tidak ada, atau sudah beda hari, hapus data lama
    await clearTodayAttendance();
    return null;
  }

  // Fungsi untuk membersihkan data absensi lokal (misalnya saat logout atau ganti hari)
  Future<void> clearTodayAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('today_attendance');
    await prefs.remove('attendance_date');
  }

  // Method untuk menghapus semua data sesi saat logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Panggil juga fungsi clear absensi lokal
    await clearTodayAttendance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_gender');
    await prefs.remove('user_photo');
    await prefs.remove('user_training');
    await prefs.remove('user_batch');
  }
}
